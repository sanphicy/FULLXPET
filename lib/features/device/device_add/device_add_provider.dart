import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 新增持久化库
import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/locator.dart';
import 'package:fullxpet/core/hardware/bluetooth_manager.dart';
import 'package:fullxpet/core/network/api_endpoints.dart';
import 'package:fullxpet/core/network/http_client.dart';
import 'models/discovered_device.dart';
import 'repositories/device_add_repository.dart';
import 'package:fullxpet/features/device/repositories/device_repository.dart';

class DeviceAddProvider extends BaseProvider {
  final _bleManager = locator<BluetoothManager>();
  final DeviceAddRepository _repository = DeviceAddRepository();

  // ================= 设置项持久化 =================
  bool _hasLoadedSettings = false;
  bool _filterUnknown = true;
  String _filterName = 'FULLXPET';
  bool _autoFetchWifi = true;

  bool _isFactoryDebugMode = false; //工厂调试
  bool get isFactoryDebugMode => _isFactoryDebugMode;

  bool get filterUnknown => _filterUnknown;
  String get filterName => _filterName;
  bool get autoFetchWifi => _autoFetchWifi;

  // 加载本地配网设置
  Future<void> loadSettings() async {
    if (_hasLoadedSettings) return;
    final prefs = await SharedPreferences.getInstance();
    _filterUnknown = prefs.getBool('pref_filter_unknown') ?? true;
    _filterName = prefs.getString('pref_filter_name') ?? 'FULLXPET';
    _autoFetchWifi = prefs.getBool('pref_auto_fetch_wifi') ?? true;
    _hasLoadedSettings = true;
    _isFactoryDebugMode = prefs.getBool('pref_factory_debug_mode') ?? false;
  }

  // 保存设置并重新应用
  Future<void> saveSettings({
    required bool filterUnknown,
    required String filterName,
    required bool autoFetchWifi,
    required bool isFactoryDebugMode,
  }) async {
    _filterUnknown = filterUnknown;
    _filterName = filterName;
    _autoFetchWifi = autoFetchWifi;
    _isFactoryDebugMode = isFactoryDebugMode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_filter_unknown', filterUnknown);
    await prefs.setString('pref_filter_name', filterName);
    await prefs.setBool('pref_auto_fetch_wifi', autoFetchWifi);
    await prefs.setBool('pref_factory_debug_mode', isFactoryDebugMode);
    await startSearchDevices(); // 设置更改后自动重新搜索
  }
  // ================================================

  bool _isScanning = false;
  List<DiscoveredDevice> _discoveredDevices = [];
  StreamSubscription<List<ScanResult>>? _scanResultsSub;
  StreamSubscription<bool>? _scanStateSub;

  bool get isScanning => _isScanning;
  List<DiscoveredDevice> get discoveredDevices => _discoveredDevices;

  String? _connectingDeviceId;
  String? get connectingDeviceId => _connectingDeviceId;

  String? _boundDeviceId;
  String? get boundDeviceId => _boundDeviceId;

  int _configStep = 0;
  bool _isFetchingWifi = false;
  List<Map<String, dynamic>> _deviceWifiList = [];
  bool _isWifiTimeout = false;

  bool _isReadyForWifi = false;
  bool get isReadyForWifi => _isReadyForWifi;

  double _progress = 0.0;
  double get progress => _progress;

  bool get isWifiTimeout => _isWifiTimeout;
  int get configStep => _configStep;
  bool get isFetchingWifi => _isFetchingWifi;
  List<Map<String, dynamic>> get deviceWifiList => _deviceWifiList;

  final List<String> _provisionLogs = [];
  List<String> get provisionLogs => _provisionLogs;

  void _addLog(String msg, {bool isHighlight = false, bool isError = false}) {
    final now = DateTime.now();
    final timeStr =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    String prefix = "";
    if (isError) {
      prefix = "❌ ";
    } else if (isHighlight) {
      prefix = "🟢 ";
    }

    final logText = "[$timeStr] $prefix$msg";
    _provisionLogs.insert(0, logText);
    notifyListeners();
  }

  void clearLogs() {
    _provisionLogs.clear();
    notifyListeners();
  }

  String _shortUuid(String fullUuid) {
    if (fullUuid.length >= 8) {
      return fullUuid.substring(4, 8).toLowerCase();
    }
    return fullUuid;
  }

  String _decodeLogBytes(List<int> bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return bytes.join(', ');
    }
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    _bleManager.stopScan();
    if (_configStep != 4) {
      _bleManager.disconnectActiveDevice();
    }
    _isScanning = false;
    super.dispose();
  }

  void resetStateForRescan() {
    _connectingDeviceId = null;
    _boundDeviceId = null;
    _configStep = 0;
    _progress = 0.0;
    _isFetchingWifi = false;
    _isReadyForWifi = false;
    _isWifiTimeout = false;
    _deviceWifiList.clear();
    _provisionLogs.clear();
    clearError();
    Future.microtask(() async {
      await _bleManager.disconnectActiveDevice();
      await startSearchDevices();
    });
  }

  void _cancelSubscriptions() {
    _scanResultsSub?.cancel();
    _scanStateSub?.cancel();
    _scanResultsSub = null;
    _scanStateSub = null;
  }

  Future<void> startSearchDevices() async {
    await loadSettings(); // 确保开始扫描前设置已加载[cite: 2]

    clearError();
    _discoveredDevices.clear();
    _cancelSubscriptions();

    final hasPermission = await _bleManager.checkAndRequestPermissions();
    if (!hasPermission) {
      setError("未获取蓝牙权限");
      return;
    }

    if (Platform.isAndroid) {
      try {
        await FlutterBluePlus.turnOn();
      } catch (_) {}
    }

    try {
      final state = await FlutterBluePlus.adapterState
          .firstWhere((s) => s == BluetoothAdapterState.on)
          .timeout(const Duration(seconds: 3));
      if (state != BluetoothAdapterState.on) throw Exception("Status is not on");
    } catch (e) {
      setError("请确保已开启蓝牙");
      return;
    }

    _isScanning = true;
    notifyListeners();

    try {
      await _bleManager.startScan(targetChipType: '', timeout: const Duration(seconds: 15));
    } catch (e) {
      setError("扫描失败");
      _isScanning = false;
      notifyListeners();
      return;
    }

    _scanResultsSub = _bleManager.scanResults.listen((results) {
      final Map<String, DiscoveredDevice> map = {};
      for (final r in results) {
        final id = r.device.remoteId.toString();
        map[id] = DiscoveredDevice(
          id: id,
          name: r.device.platformName.isNotEmpty ? r.device.platformName : "Unknown Device",
          rssi: r.rssi,
          device: r.device,
        );
      }

      // 应用动态过滤规则
      _discoveredDevices = map.values.where((d) {
        // 规则1：过滤未知设备
        if (_filterUnknown && (d.name == "Unknown Device" || d.name.isEmpty)) {
          return false;
        }
        // 规则2：精确名称过滤（包含即可）
        if (_filterName.isNotEmpty && !d.name.toUpperCase().contains(_filterName.toUpperCase())) {
          return false;
        }
        return true;
      }).toList()..sort((a, b) => b.rssi.compareTo(a.rssi));

      notifyListeners();
    });

    _scanStateSub = _bleManager.isScanningStream.listen((scanning) {
      if (!scanning && _isScanning) {
        _isScanning = false;
        _cancelSubscriptions();
        notifyListeners();
      }
    });
  }

  Future<void> _stopSearchDevices() async {
    if (_isScanning) {
      await _bleManager.stopScan();
    }
  }

  Future<void> _send0x86Data(String deviceId, Map<String, dynamic> jsonMap) async {
    final String jsonStr = jsonEncode(jsonMap);
    final List<int> jsonData = utf8.encode(jsonStr);
    final int totalLength = jsonData.length;

    if (totalLength > 255) throw Exception("JSON 长度超过 255 字节限制");

    List<List<int>> packets = [];
    int firstPacketDataLen = totalLength > 18 ? 18 : totalLength;
    List<int> firstPacket = [0x86, totalLength];
    firstPacket.addAll(jsonData.sublist(0, firstPacketDataLen));
    packets.add(firstPacket);

    int offset = firstPacketDataLen;
    while (offset < totalLength) {
      int remaining = totalLength - offset;
      int chunkLen = remaining > 20 ? 20 : remaining;
      packets.add(jsonData.sublist(offset, offset + chunkLen));
      offset += chunkLen;
    }

    for (List<int> packet in packets) {
      await _bleManager.writeData(deviceId: deviceId, data: packet);
      await Future.delayed(const Duration(milliseconds: 15));
    }
    _addLog("Bk7238NoticeEnum.BLE_WRITE_SUCCESS");
  }

  Future<bool> prepareAndFetchWifi(DiscoveredDevice targetDevice) async {
    await _stopSearchDevices();

    clearLogs();
    clearError();
    _configStep = 0;
    _progress = 0.05;
    _connectingDeviceId = targetDevice.id;
    _isFetchingWifi = true;
    _isReadyForWifi = false;
    _deviceWifiList.clear();
    notifyListeners();

    _addLog("设备开始连接");
    final connectSuccess = await _bleManager.connectToDevice(targetDevice.device!);

    if (!connectSuccess) {
      _connectingDeviceId = null;
      _isFetchingWifi = false;
      _isReadyForWifi = true;
      _progress = 0.0;
      _addLog("设备状态变化: 断开", isError: true);
      _addLog("蓝牙连接失败，请靠近设备重试", isError: true);
      setError("连接蓝牙失败");
      notifyListeners();
      return false;
    }

    _progress = 0.15;
    _addLog("设备状态变化: 已连接");
    _addLog("蓝牙底层连接成功", isHighlight: true);

    StreamSubscription<List<int>>? notifySub;
    bool isSuccess = false;

    try {
      List<BluetoothService> services = await targetDevice.device!.discoverServices();
      for (var service in services) {
        String sUuid = _shortUuid(service.uuid.toString());
        _addLog("寻找到服务$sUuid");
        for (var characteristic in service.characteristics) {
          String cUuid = _shortUuid(characteristic.uuid.toString());
          _addLog("寻找到子服务${cUuid}true");
        }
      }
      _addLog("获取服务成功");

      final stream = await _bleManager.subscribeToNotifications(deviceId: _connectingDeviceId!);

      _progress = 0.25;
      _addLog("特征值订阅成功", isHighlight: true);

      Completer<void> completer = Completer();
      List<int> receiveBuffer = [];
      int expectedLength = 0;

      notifySub = stream.listen((value) {
        if (value.isEmpty) return;

        if (expectedLength == 0 && value[0] == 0x86 && value.length >= 2) {
          expectedLength = value[1];
          receiveBuffer.clear();
          receiveBuffer.addAll(value.sublist(2));
        } else {
          receiveBuffer.addAll(value);
        }

        if (receiveBuffer.length >= expectedLength && expectedLength > 0) {
          final validBytes = receiveBuffer.sublist(0, expectedLength);
          try {
            final data = jsonDecode(utf8.decode(validBytes));

            if (data['method'] == 'devConfSsidRsp') {
              if (data['list'] != null) {
                final List list = data['list'];
                _deviceWifiList = list
                    .map((item) => {"ssid": item[0].toString(), "channel": item[1] as int, "rssi": item[2] as int})
                    .toList();

                _deviceWifiList.sort((a, b) => (b['rssi'] as int).compareTo(a['rssi'] as int));

                final ssidNames = _deviceWifiList.map((e) => e['ssid']).join(', ');
                _addLog("共解析出 ${_deviceWifiList.length} 条可用网络: $ssidNames");

                if (!completer.isCompleted) completer.complete();
              } else {
                if (!completer.isCompleted) {
                  completer.completeError(Exception("获取 Wi-Fi 列表格式异常"));
                }
              }
            } else {
              _addLog("来自ff01 [${_decodeLogBytes(validBytes)}]");
            }
          } catch (e) {
            _isWifiTimeout = true;
          } finally {
            receiveBuffer.clear();
            expectedLength = 0;
          }
        }
      });

      // 根据设置动态决定是否下发周边Wi-Fi扫描指令[cite: 2]
      if (_autoFetchWifi) {
        _addLog("正在获取设备WiFi列表...");
        await _send0x86Data(_connectingDeviceId!, {"method": "devConfSsidGet"});

        await completer.future.timeout(const Duration(seconds: 30));
        _progress = 0.35;
        _addLog("周边网络列表获取成功，等待确认", isHighlight: true);
      } else {
        _progress = 0.35;
        _addLog("已关闭设备扫描，跳过获取，使用当前手机Wi-Fi", isHighlight: true);
        await Future.delayed(const Duration(milliseconds: 500)); // 缓冲体验
      }
      isSuccess = true;
    } catch (e) {
      _addLog("特征值交互或 Wi-Fi 列表拉取超时", isError: true);
      _isWifiTimeout = true;
    } finally {
      notifySub?.cancel();
      _isFetchingWifi = false;
      _isReadyForWifi = true;
      notifyListeners();
    }

    return isSuccess;
  }

  Future<bool> startWifiProvisioning(String ssid, String password, DiscoveredDevice targetDevice) async {
    if (ssid.isEmpty || password.isEmpty) {
      setError("Wi-Fi 或密码不能为空");
      return false;
    }

    clearError();
    _configStep = 1;
    _isReadyForWifi = false;
    notifyListeners();

    _addLog("拉取云端 MQTT Token 与加密配置");
    final mqttUrl = await _repository.getDeviceMqttRui();
    if (mqttUrl == null) {
      _addLog("获取云端 MQTT 参数失败", isError: true);
      _configStep = 0;
      _isReadyForWifi = true;
      setError("获取 MQTT 配置失败");
      return false;
    }

    int channel = 1;
    try {
      final wifiInfo = _deviceWifiList.firstWhere((w) => w['ssid'] == ssid);
      channel = wifiInfo['channel'] as int;
    } catch (_) {}

    final int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final int timeOffset = DateTime.now().timeZoneOffset.inSeconds;

    StreamSubscription<List<int>>? notifySub;
    Completer<bool> completer = Completer();

    try {
      final stream = await _bleManager.subscribeToNotifications(deviceId: targetDevice.id);
      List<int> receiveBuffer = [];
      int expectedLength = 0;

      notifySub = stream.listen((value) async {
        if (value.isEmpty) return;

        if (expectedLength == 0 && value[0] == 0x86 && value.length >= 2) {
          expectedLength = value[1];
          receiveBuffer.clear();
          receiveBuffer.addAll(value.sublist(2));
        } else {
          receiveBuffer.addAll(value);
        }

        if (receiveBuffer.length >= expectedLength && expectedLength > 0) {
          try {
            final validBytes = receiveBuffer.sublist(0, expectedLength);
            final dynamic decodedJson = jsonDecode(utf8.decode(validBytes));

            final Map<String, dynamic>? data = (decodedJson is List && decodedJson.isNotEmpty)
                ? decodedJson.first as Map<String, dynamic>
                : (decodedJson is Map ? decodedJson as Map<String, dynamic> : null);

            if (data != null) {
              if (data['payload'] != null && data['payload']['msg'] != null) {
                final String deviceMsg = data['payload']['msg'].toString();
                _addLog("来自ff01 设备消息: $deviceMsg");
              }

              if (data['method'] == 'confNotify' && data['payload'] != null) {
                final payload = data['payload'];
                final int stage = payload['stage'] ?? 0;
                final int code = payload['code'] ?? -1;

                if (stage == 1 && code == 0) {
                  _progress = 0.6;
                  _addLog("Bk7238NoticeEnum.WIFICONNECTING");
                  _addLog("设备正在尝试连接路由器", isHighlight: true);
                  _configStep = 2;
                  notifyListeners();
                } else if (stage == 2 && code == 0) {
                  _progress = 0.8;
                  _addLog("Bk7238NoticeEnum.WIFICONNECTED");
                  _addLog("路由器连接成功！正在向云端注册设备", isHighlight: true);
                  _configStep = 3;
                  notifyListeners();

                  final String mac = payload['mac']?.toString() ?? '';
                  final String pid = payload['pid']?.toString() ?? '';

                  final String realDeviceId = payload['deviceId']?.toString() ?? '';
                  _boundDeviceId = realDeviceId;

                  final defaultNickname = targetDevice.name.isNotEmpty ? targetDevice.name : "FULLXPET";

                  _bindDeviceToCloud(mac, pid, defaultNickname).then((isBindSuccess) {
                    if (isBindSuccess) {
                      _progress = 1.0;
                      _addLog("设备云端注册完成！", isHighlight: true);

                      final device = locator<DeviceRepository>().getDevice(realDeviceId);
                      device.productId = pid;
                      device.deviceName = defaultNickname;

                      if (!completer.isCompleted) completer.complete(true);
                    } else {
                      if (!completer.isCompleted) completer.completeError(Exception("绑定设备失败，请重试"));
                    }
                  });
                } else if (stage == 2 && code != 0) {
                  if (!completer.isCompleted) {
                    String errMsg = payload['msg'] == 'password_error' ? "Wi-Fi 密码错误或信号极弱" : "网络连接中断";
                    completer.completeError(Exception(errMsg));
                  }
                }
              }
            }
          } catch (_) {
          } finally {
            receiveBuffer.clear();
            expectedLength = 0;
          }
        }
      });

      _progress = 0.45;
      _addLog("下发配网数据");
      await _send0x86Data(targetDevice.id, {
        "method": "devConf",
        "payload": {
          "ssid": ssid,
          "pssw": password,
          "ch": channel,
          "uuid": "9527",
          "tsmp": timestamp,
          "bsid": "xxxxx",
          "url": mqttUrl,
          "timeOffset": timeOffset,
        },
      });

      return await completer.future.timeout(const Duration(seconds: 40));
    } catch (e) {
      _configStep = 0;
      _isReadyForWifi = true;
      String errorMsg = e.toString().contains("Exception:") ? e.toString().split("Exception: ").last : "配网异常或超时";
      _addLog("配网中断: $errorMsg", isError: true);
      setError(errorMsg);
      return false;
    } finally {
      notifySub?.cancel();
      await _bleManager.unsubscribeFromNotifications(deviceId: targetDevice.id);

      if (!hasError && _configStep == 3) {
        _configStep = 4;
        notifyListeners();
      }
    }
  }

  Future<bool> _bindDeviceToCloud(String mac, String pid, String nickname) async {
    try {
      final homeListRes = await locator<HttpClient>().get<Map<String, dynamic>>(ApiEndpoints.homeList);
      final items = homeListRes.data?['items'] as List?;
      if (items == null || items.isEmpty) return false;

      final homeId = items[0]['id']?.toString() ?? '';
      final homeInfo = await locator<HttpClient>().get<Map<String, dynamic>>(ApiEndpoints.homeInfo(homeId));

      String roomId = "";
      final responseData = homeInfo.data?['data'] ?? homeInfo.data;
      if (responseData != null && responseData['rooms'] != null) {
        final List rooms = responseData['rooms'];
        if (rooms.isNotEmpty) {
          roomId = rooms[0]['id']?.toString() ?? "";
        }
      }

      final Map<String, dynamic> bindPayload = {
        "hardwareId": mac,
        "productId": pid,
        "roomId": roomId,
        "nickname": nickname,
        "bindSource": Platform.isAndroid ? "android" : "ios",
        "locallyBound": false,
      };

      final DateTime endTime = DateTime.now().add(const Duration(minutes: 1));
      const Duration pollInterval = Duration(seconds: 3);

      while (DateTime.now().isBefore(endTime)) {
        try {
          final bindResult = await locator<HttpClient>().post(ApiEndpoints.deviceBind(homeId), data: bindPayload);
          if (bindResult.code == 0 || bindResult.code == 200) {
            return true;
          }
        } catch (_) {}
        await Future.delayed(pollInterval);
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
