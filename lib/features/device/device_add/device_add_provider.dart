import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/common/providers/user_provider.dart';
import 'package:fullxpet/core/hardware/bluetooth_manager.dart';
import 'package:fullxpet/locator.dart';
import 'models/discovered_device.dart';
import 'repositories/device_add_repository.dart';
import 'package:fullxpet/features/device/device_add/models/ble_packet_codec.dart';

typedef ScanResultList = List<ScanResult>;

class DeviceAddProvider extends BaseProvider with WidgetsBindingObserver {
  static const String kBleDisconnectedPrompt = "蓝牙断开，请返回列表重新配对";

  final BluetoothManager _bleManager = locator<BluetoothManager>();
  final DeviceAddRepository _repository = DeviceAddRepository();

  DeviceAddProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  // ================= 设置项持久化 =================
  bool _hasLoadedSettings = false;
  bool _filterUnknown = true;
  String _filterName = 'pet, junvine';
  bool _autoFetchWifi = true;

  bool get filterUnknown => _filterUnknown;
  String get filterName => _filterName;
  bool get autoFetchWifi => _autoFetchWifi;

  Future<void> loadSettings() async {
    if (_hasLoadedSettings) return;
    final prefs = await SharedPreferences.getInstance();
    _filterUnknown = prefs.getBool('pref_filter_unknown') ?? true;
    _filterName = prefs.getString('pref_filter_name') ?? 'pet, junvine';
    _autoFetchWifi = prefs.getBool('pref_auto_fetch_wifi') ?? true;
    _hasLoadedSettings = true;
  }

  Future<void> saveSettings({
    required bool filterUnknown,
    required String filterName,
    required bool autoFetchWifi,
  }) async {
    _filterUnknown = filterUnknown;
    _filterName = filterName;
    _autoFetchWifi = autoFetchWifi;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_filter_unknown', filterUnknown);
    await prefs.setString('pref_filter_name', filterName);
    await prefs.setBool('pref_auto_fetch_wifi', autoFetchWifi);
    await startSearchDevices();
  }
  // ================================================

  bool _isScanning = false;
  List<DiscoveredDevice> _discoveredDevices = [];
  StreamSubscription<ScanResultList>? _scanResultsSub;
  StreamSubscription<bool>? _scanStateSub;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSub;
  final Set<String> _printedDeviceIds = {};

  bool get isScanning => _isScanning;
  List<DiscoveredDevice> get discoveredDevices => _discoveredDevices;

  DiscoveredDevice? _activeTargetDevice;
  DiscoveredDevice? get activeTargetDevice => _activeTargetDevice;
  String? _connectingDeviceId;
  String? get connectingDeviceId => _connectingDeviceId;

  String? _boundDeviceId;
  String? get boundDeviceId => _boundDeviceId;
  String? _boundProductId;
  String? get boundProductId => _boundProductId;
  bool _isBleConnected = false;
  bool get isBleConnected => _isBleConnected;

  int _configStep = 0;
  bool _isFetchingWifi = false;
  List<WifiMap> _deviceWifiList = [];
  bool _isWifiTimeout = false;
  bool _isReadyForWifi = false;
  double _progress = 0.0;

  int get configStep => _configStep;
  bool get isFetchingWifi => _isFetchingWifi;
  List<WifiMap> get deviceWifiList => _deviceWifiList;
  bool get isWifiTimeout => _isWifiTimeout;
  bool get isReadyForWifi => _isReadyForWifi;
  double get progress => _progress;

  final List<String> _provisionLogs = [];
  List<String> get provisionLogs => _provisionLogs;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (_activeTargetDevice != null && _configStep == 0) {
        final rawDevice = _activeTargetDevice!.device;
        if (rawDevice != null && !rawDevice.isConnected && _isBleConnected) {
          _handleUnexpectedBleDisconnect();
        }
      }
    }
  }

  void selectTargetDevice(DiscoveredDevice device) {
    _activeTargetDevice = device;
  }

  void _handleUnexpectedBleDisconnect() {
    _isBleConnected = false;
    if (_configStep == 0) {
      _isFetchingWifi = false;
      _isReadyForWifi = true;
      _addLog(kBleDisconnectedPrompt, isError: true);
      setError(kBleDisconnectedPrompt);
      notifyListeners();
    }
  }

  String _formatBleError(Object error) {
    final raw = error.toString();
    final lower = raw.toLowerCase();
    if (raw.contains("未连接") ||
        raw.contains("断开") ||
        lower.contains("not connected") ||
        lower.contains("disconnected") ||
        lower.contains("fbp-code: 6") ||
        lower.contains("gatt")) {
      return kBleDisconnectedPrompt;
    }
    if (raw.contains("Exception:")) {
      return raw.split("Exception:").last.trim();
    }
    return "配网异常或超时";
  }

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

    _provisionLogs.insert(0, "[$timeStr] $prefix$msg");
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
    WidgetsBinding.instance.removeObserver(this);
    _cancelSubscriptions();
    _connectionStateSub?.cancel();
    _bleManager.stopScan();
    if (_configStep != 4) {
      _bleManager.disconnectActiveDevice();
    }
    _isScanning = false;
    super.dispose();
  }

  void resetStateForRescan() {
    _connectionStateSub?.cancel();
    _connectionStateSub = null;
    _activeTargetDevice = null;
    _connectingDeviceId = null;
    _boundDeviceId = null;
    _boundProductId = null;
    _isBleConnected = false;
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
    await loadSettings();

    clearError();
    _discoveredDevices.clear();
    _printedDeviceIds.clear();
    _cancelSubscriptions();

    _repository.fetchProductList().then((products) {
      if (products.isNotEmpty && _discoveredDevices.isNotEmpty) {
        _discoveredDevices = _discoveredDevices.map((d) {
          final matched = d.hasShortPid
              ? _repository.findProductByShortId(d.shortPid)
              : _repository.findProductByFullId(d.pid);
          return d.applyProductInfo(matched);
        }).toList();
        notifyListeners();
      }
    });

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
      final Map<String, ScanResult> rawResultMap = {};
      final Map<String, DiscoveredDevice> map = {};

      for (final r in results) {
        final id = r.device.remoteId.toString();
        final name = r.device.platformName.isNotEmpty
            ? r.device.platformName
            : (r.advertisementData.advName.isNotEmpty ? r.advertisementData.advName : "Unknown Device");

        rawResultMap[id] = r;

        String parsedMac = '';
        String parsedShortPid = '';

        r.advertisementData.manufacturerData.forEach((vendorId, bytes) {
          final int b1 = vendorId & 0xFF;
          final int b2 = (vendorId >> 8) & 0xFF;
          final List<int> fullAdvBytes = [b1, b2, ...bytes];

          if (fullAdvBytes.length >= 11) {
            try {
              parsedShortPid = fullAdvBytes
                  .sublist(3, 5)
                  .map((b) => b.toRadixString(16).padLeft(2, '0'))
                  .join('')
                  .toLowerCase();
              parsedMac = fullAdvBytes
                  .sublist(5, 11)
                  .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
                  .join(':');
            } catch (_) {}
          }
        });

        if (parsedMac.isEmpty && RegExp(r'^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$').hasMatch(id)) {
          parsedMac = id.toUpperCase();
        }

        map[id] = _repository.buildDiscoveredDevice(
          id: id,
          name: name,
          rssi: r.rssi,
          device: r.device,
          parsedMac: parsedMac,
          parsedShortPid: parsedShortPid,
        );
      }

      _discoveredDevices = map.values.where((d) {
        if (_filterUnknown && (d.name == "Unknown Device" || d.name.isEmpty)) {
          return false;
        }
        if (_filterName.isNotEmpty) {
          final filterKeywords = _filterName
              .replaceAll('，', ',')
              .split(',')
              .map((e) => e.trim().toUpperCase())
              .where((e) => e.isNotEmpty)
              .toList();

          if (filterKeywords.isNotEmpty) {
            final deviceNameUpper = d.name.toUpperCase();
            final bool isMatchAny = filterKeywords.any((kw) => deviceNameUpper.contains(kw));
            if (!isMatchAny) return false;
          }
        }
        return true;
      }).toList()..sort((a, b) => b.rssi.compareTo(a.rssi));

      for (final device in _discoveredDevices) {
        if (!_printedDeviceIds.contains(device.id)) {
          _printedDeviceIds.add(device.id);
          final rawScanResult = rawResultMap[device.id];
          if (rawScanResult != null) {
            _printScanResultDetails(rawScanResult, device);
          }
        }
      }

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

  void _printScanResultDetails(ScanResult r, DiscoveredDevice parsedDevice) {
    final adv = r.advertisementData;
    debugPrint("╔══════════════════════════════════════════════════════════");
    debugPrint("║ 【扫描列表设备广播详情】名称: ${parsedDevice.name} | 信号: ${r.rssi} dBm");
    debugPrint("║ • 标记配网方式 : ${parsedDevice.provisionMode.name}");
    debugPrint("║ • 短产品ID     : ${parsedDevice.shortPid.isEmpty ? '无(走hooget名称映射)' : parsedDevice.shortPid}");
    debugPrint("║ • 完整产品PID  : ${parsedDevice.pid.isEmpty ? '暂未匹配' : parsedDevice.pid}");
    debugPrint("║ • 广播解析MAC  : ${parsedDevice.mac}");
    debugPrint("║ • 网络图标URL  : ${parsedDevice.iconUrl ?? '未命中(使用保底图标)'}");
    if (adv.manufacturerData.isNotEmpty) {
      adv.manufacturerData.forEach((vendorId, bytes) {
        final int b1 = vendorId & 0xFF;
        final int b2 = (vendorId >> 8) & 0xFF;
        final List<int> fullAdvBytes = [b1, b2, ...bytes];
        final String fullHex = fullAdvBytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
        debugPrint("║ • 完整广播HEX  : [$fullHex]");
      });
    }
    debugPrint("╚══════════════════════════════════════════════════════════");
  }

  Future<void> _stopSearchDevices() async {
    if (_isScanning) {
      await _bleManager.stopScan();
    }
  }

  Future<void> _sendBleJson(DiscoveredDevice targetDevice, WifiMap jsonMap, BlePacketCodec codec) async {
    if (targetDevice.device == null || !_isBleConnected) {
      throw Exception(kBleDisconnectedPrompt);
    }

    final packets = codec.encode(jsonMap);
    if (packets.isEmpty) return;

    _addLog("下发数据(${targetDevice.provisionMode.name}): 共 ${packets.length} 包");
    for (final packet in packets) {
      await _bleManager.writeData(deviceId: targetDevice.id, data: packet);
      await Future.delayed(const Duration(milliseconds: 15));
    }
  }

  Future<bool> prepareAndFetchWifi(DiscoveredDevice targetDevice) async {
    await _stopSearchDevices();

    clearLogs();
    clearError();
    _configStep = 0;
    _progress = 0.05;
    _activeTargetDevice = targetDevice;
    _connectingDeviceId = targetDevice.id;
    _isFetchingWifi = true;
    _isReadyForWifi = false;
    _isBleConnected = false;
    _deviceWifiList.clear();
    notifyListeners();

    _addLog(
      "配网方式: ${targetDevice.provisionMode.name} (短ID:${targetDevice.shortPid}, PID:${targetDevice.pid})",
      isHighlight: true,
    );
    _addLog("设备开始连接");

    final connectSuccess = await _bleManager.connectToDevice(targetDevice.device!);
    if (!connectSuccess) {
      _connectingDeviceId = null;
      _isFetchingWifi = false;
      _isReadyForWifi = true;
      _progress = 0.0;
      _addLog(kBleDisconnectedPrompt, isError: true);
      setError(kBleDisconnectedPrompt);
      notifyListeners();
      return false;
    }

    _isBleConnected = true;
    _progress = 0.15;
    _addLog("蓝牙底层连接成功", isHighlight: true);

    _connectionStateSub?.cancel();
    _connectionStateSub = targetDevice.device!.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        if (_isBleConnected) {
          _handleUnexpectedBleDisconnect();
        }
      } else if (state == BluetoothConnectionState.connected) {
        _isBleConnected = true;
      }
    });

    StreamSubscription<BlePacket>? notifySub;
    bool isSuccess = false;

    try {
      final List<BluetoothService> services = await targetDevice.device!.discoverServices();
      for (final service in services) {
        final String sUuid = _shortUuid(service.uuid.toString());
        _addLog("寻找到服务$sUuid");
        for (final characteristic in service.characteristics) {
          final String cUuid = _shortUuid(characteristic.uuid.toString());
          _addLog("寻找到子服务${cUuid}true");
        }
      }
      _addLog("获取服务成功");

      final stream = await _bleManager.subscribeToNotifications(deviceId: _connectingDeviceId!);
      _progress = 0.25;
      _addLog("特征值订阅成功", isHighlight: true);

      final Completer<void> wifiCompleter = Completer();
      final BlePacketCodec codec = BlePacketCodec(mode: targetDevice.provisionMode);

      notifySub = stream.listen((value) {
        final completeBytes = codec.onReceiveChunk(value);
        if (completeBytes == null) return;

        try {
          final String jsonStr = utf8.decode(completeBytes);
          final data = jsonDecode(jsonStr);

          if (data['method'] == 'devConfSsidRsp') {
            if (data['list'] != null) {
              final List list = data['list'];
              _deviceWifiList = list
                  .map((item) => {"ssid": item[0].toString(), "channel": item[1] as int, "rssi": item[2] as int})
                  .toList();

              _deviceWifiList.sort((a, b) => (b['rssi'] as int).compareTo(a['rssi'] as int));
              final ssidNames = _deviceWifiList.map((e) => e['ssid']).join(', ');
              _addLog("共解析出 ${_deviceWifiList.length} 条可用网络: $ssidNames");

              if (!wifiCompleter.isCompleted) wifiCompleter.complete();
            } else {
              if (!wifiCompleter.isCompleted) wifiCompleter.completeError(Exception("获取 Wi-Fi 列表格式异常"));
            }
          } else {
            _addLog("来自ff01 [${_decodeLogBytes(completeBytes)}]");
          }
        } catch (e) {
          _addLog("JSON解析异常: $e", isError: true);
          _isWifiTimeout = true;
        }
      });

      if (_autoFetchWifi) {
        _addLog("正在获取设备WiFi列表...");
        await _sendBleJson(targetDevice, {"method": "devConfSsidGet"}, codec);
        await wifiCompleter.future.timeout(const Duration(seconds: 30));
        _progress = 0.35;
        _addLog("周边网络列表获取成功，等待确认", isHighlight: true);
      } else {
        _progress = 0.35;
        _addLog("已关闭设备扫描，跳过获取，使用当前手机Wi-Fi", isHighlight: true);
        await Future.delayed(const Duration(milliseconds: 500));
      }
      isSuccess = true;
    } catch (e) {
      if (!_isBleConnected || (targetDevice.device != null && !targetDevice.device!.isConnected)) {
        _addLog(kBleDisconnectedPrompt, isError: true);
        setError(kBleDisconnectedPrompt);
      } else {
        _addLog("特征值交互或 Wi-Fi 列表拉取超时", isError: true);
        _isWifiTimeout = true;
      }
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

    if (targetDevice.device == null || !_isBleConnected) {
      _configStep = 0;
      _isReadyForWifi = true;
      _addLog(kBleDisconnectedPrompt, isError: true);
      setError(kBleDisconnectedPrompt);
      notifyListeners();
      return false;
    }

    clearError();
    _configStep = 1;
    _isReadyForWifi = false;
    notifyListeners();

    if (_repository.cachedProducts.isEmpty) {
      await _repository.fetchProductList();
    }

    _addLog("拉取云端注册配置");
    final cloudRegisterUrl = await _repository.getDeviceMqttRui(mode: targetDevice.provisionMode);
    _addLog("下发请求地址:$cloudRegisterUrl");

    if (cloudRegisterUrl == null) {
      _addLog("获取云端注册参数失败", isError: true);
      _configStep = 0;
      _isReadyForWifi = true;
      setError("获取云端配置失败");
      return false;
    }

    final currentUser = locator<UserProvider>().user;
    final currentUserId = currentUser.userId.trim();
    final String provisionUuid = currentUserId.isNotEmpty ? currentUserId : "9527";

    int channel = 1;
    try {
      final wifiInfo = _deviceWifiList.firstWhere((w) => w['ssid'] == ssid);
      channel = wifiInfo['channel'] as int;
    } catch (_) {}

    final int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final int timeOffset = DateTime.now().timeZoneOffset.inSeconds;

    StreamSubscription<BlePacket>? notifySub;
    final Completer<bool> completer = Completer();
    final BlePacketCodec codec = BlePacketCodec(mode: targetDevice.provisionMode);

    bool isBindingStarted = false;
    Timer? stage0DelayTimer;

    void triggerJunvineBind({required String mac, required String pid, required String deviceId}) {
      if (isBindingStarted) return;
      if (mac.isEmpty || pid.isEmpty) {
        _addLog("无法绑定：未获取到有效 MAC($mac) 或 产品ID($pid)", isError: true);
        if (!completer.isCompleted) {
          completer.completeError(Exception("未匹配到有效的产品ID，无法绑定设备"));
        }
        return;
      }
      isBindingStarted = true;
      _progress = 0.8;
      _configStep = 3;
      _boundDeviceId = deviceId.isNotEmpty ? deviceId : mac;
      _boundProductId = pid;
      notifyListeners();

      final defaultNickname = targetDevice.name.isNotEmpty ? targetDevice.name : "FULLXPET";
      _addLog("开始向云端轮询绑定设备 (MAC: $mac, PID: $pid)", isHighlight: true);

      _repository.bindDeviceToCloud(mac: mac, pid: pid, nickname: defaultNickname, mode: ProvisionMode.junvine).then((
        isBindSuccess,
      ) {
        if (isBindSuccess) {
          clearError();
          _progress = 1.0;
          _configStep = 3;
          _addLog("设备云端注册绑定完成！", isHighlight: true);
          if (!completer.isCompleted) completer.complete(true);
        } else {
          if (!completer.isCompleted) {
            completer.completeError(Exception("绑定设备超时或失败，请重试"));
          }
        }
      });
    }

    try {
      final stream = await _bleManager.subscribeToNotifications(deviceId: targetDevice.id);

      notifySub = stream.listen((value) async {
        final completeBytes = codec.onReceiveChunk(value);
        if (completeBytes == null) return;

        try {
          final String jsonStr = utf8.decode(completeBytes);
          final dynamic decodedJson = jsonDecode(jsonStr);

          final WifiMap? data = (decodedJson is List && decodedJson.isNotEmpty)
              ? decodedJson.first as WifiMap
              : (decodedJson is Map ? Map<String, dynamic>.from(decodedJson) : null);

          if (data == null) return;

          if (data['payload'] != null && data['payload']['msg'] != null) {
            _addLog("来自ff01 设备消息: ${data['payload']['msg']}");
          }

          if (data['method'] == 'confNotify' && data['payload'] != null) {
            final payload = data['payload'];
            final int stage = payload['stage'] ?? 0;
            final int code = payload['code'] ?? -1;

            // =================== 1. hooget 原版配网方式 ===================
            if (targetDevice.provisionMode == ProvisionMode.hooget) {
              if (stage == 1 && code == 0) {
                _progress = 0.6;
                _addLog("Bk7238NoticeEnum.WIFICONNECTING");
                _addLog("设备正在尝试连接路由器", isHighlight: true);
                _configStep = 2;
                notifyListeners();
              } else if (stage == 2 && code == 0) {
                if (isBindingStarted) return;

                final String mac = payload['mac']?.toString().trim() ?? '';
                final String callbackPid = payload['pid']?.toString().trim() ?? '';
                final String finalPid = callbackPid.isNotEmpty ? callbackPid : targetDevice.pid;
                final String realDeviceId = payload['deviceId']?.toString().trim() ?? mac;

                if (mac.isEmpty || finalPid.isEmpty) {
                  _addLog("无法绑定：未获取到有效 MAC($mac) 或 产品ID($finalPid)", isError: true);
                  if (!completer.isCompleted) {
                    completer.completeError(Exception("未获取到有效的产品ID，无法绑定设备"));
                  }
                  return;
                }

                isBindingStarted = true;
                _progress = 0.8;
                _addLog("Bk7238NoticeEnum.WIFICONNECTED");
                _addLog("路由器连接成功！正在向云端注册设备 (MAC: $mac, PID: $finalPid)", isHighlight: true);
                _configStep = 3;
                _boundDeviceId = realDeviceId;
                _boundProductId = finalPid;
                notifyListeners();

                final defaultNickname = targetDevice.name.isNotEmpty ? targetDevice.name : "FULLXPET";

                _repository
                    .bindDeviceToCloud(mac: mac, pid: finalPid, nickname: defaultNickname, mode: ProvisionMode.hooget)
                    .then((isBindSuccess) {
                      if (isBindSuccess) {
                        clearError();
                        _progress = 1.0;
                        _configStep = 3;
                        _addLog("设备云端注册完成！", isHighlight: true);
                        if (!completer.isCompleted) completer.complete(true);
                      } else {
                        if (!completer.isCompleted) completer.completeError(Exception("绑定设备失败，请重试"));
                      }
                    });
              } else if (stage == 2 && code != 0) {
                if (!completer.isCompleted) {
                  final String errMsg = payload['msg'] == 'password_error' ? "Wi-Fi 密码错误或信号极弱" : "网络连接中断";
                  completer.completeError(Exception(errMsg));
                }
              }
            }
            // =================== 2. junvine 骏云配网方式 ===================
            else {
              final String notifyMac = payload['mac']?.toString().trim() ?? '';
              final String notifyPid = payload['pid']?.toString().trim() ?? '';
              final String realDeviceId = payload['deviceId']?.toString().trim() ?? '';

              final String finalMac = notifyMac.isNotEmpty ? notifyMac : targetDevice.mac;
              String finalPid = notifyPid.isNotEmpty ? notifyPid : targetDevice.pid;
              if (finalPid.isEmpty && targetDevice.hasShortPid) {
                finalPid = _repository.findProductByShortId(targetDevice.shortPid)?.productId ?? '';
              }

              if (stage == 1 && code == 0) {
                stage0DelayTimer?.cancel();
                if (!isBindingStarted) {
                  _progress = 0.6;
                  _configStep = 2;
                }
                _addLog("设备正在尝试连接路由器", isHighlight: true);
                notifyListeners();
              } else if (stage == 2 && code == 0) {
                stage0DelayTimer?.cancel();
                triggerJunvineBind(mac: finalMac, pid: finalPid, deviceId: realDeviceId);
              } else if (stage == 0 && code == 0) {
                if (notifyMac.isNotEmpty) {
                  triggerJunvineBind(mac: finalMac, pid: finalPid, deviceId: realDeviceId);
                } else {
                  _addLog("设备已确认接收配网参数，准备向云端注册...", isHighlight: true);
                  stage0DelayTimer?.cancel();
                  stage0DelayTimer = Timer(const Duration(milliseconds: 1500), () {
                    triggerJunvineBind(mac: finalMac, pid: finalPid, deviceId: realDeviceId);
                  });
                }
              } else if (code != 0) {
                stage0DelayTimer?.cancel();
                if (!completer.isCompleted) {
                  final String errMsg = payload['msg'] == 'password_error' ? "Wi-Fi 密码错误或信号极弱" : "网络连接中断";
                  completer.completeError(Exception(errMsg));
                }
              }
            }
          }
        } catch (e) {
          _addLog("配网响应解析异常: $e", isError: true);
        }
      });

      _progress = 0.45;
      _addLog("下发配网数据");

      await _sendBleJson(targetDevice, {
        "method": "devConf",
        "payload": {
          "ssid": ssid,
          "pssw": password,
          "ch": channel,
          "uuid": provisionUuid,
          "tsmp": timestamp,
          "bsid": targetDevice.provisionMode == ProvisionMode.hooget ? "xxxxx" : "",
          "url": cloudRegisterUrl,
          "timeOffset": timeOffset,
        },
      }, codec);

      return await completer.future.timeout(const Duration(seconds: 60));
    } catch (e) {
      _configStep = 0;
      _isReadyForWifi = true;
      final String friendlyError = _formatBleError(e);
      _addLog("配网中断: $friendlyError", isError: true);
      setError(friendlyError);
      return false;
    } finally {
      stage0DelayTimer?.cancel();
      notifySub?.cancel();
      try {
        await _bleManager.unsubscribeFromNotifications(deviceId: targetDevice.id);
      } catch (_) {}

      if (!hasError && _configStep == 3) {
        _configStep = 4;
        notifyListeners();
      }
    }
  }
}
