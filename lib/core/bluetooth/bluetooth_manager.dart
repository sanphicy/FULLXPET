import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothManager with WidgetsBindingObserver {
  int _connectionSessionId = 0;

  /// 蓝牙是否已开启
  bool get isBluetoothOn => FlutterBluePlus.adapterStateNow == BluetoothAdapterState.on;

  /// 扫描结果流
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  /// 是否正在扫描流
  Stream<bool> get isScanningStream => FlutterBluePlus.isScanning;

  /// 设备连接状态广播流，供上层 ViewModel 监听断连状态
  final StreamController<BluetoothConnectionState> _connectionStateController =
      StreamController<BluetoothConnectionState>.broadcast();
  Stream<BluetoothConnectionState> get connectionStateStream => _connectionStateController.stream;

  StreamSubscription<List<ScanResult>>? _scanResultsSub;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSub;

  /// 当前正在交互的设备
  BluetoothDevice? _activeDevice;

  /// 策略配置：App 切到后台时，是否保持蓝牙连接 (默认 false：退到后台自动断开)
  bool keepConnectionInBackground = false;

  /// 初始化蓝牙管理器并注册生命周期监听
  void init() {
    _startListeningToScanResults();
    WidgetsBinding.instance.addObserver(this);
  }

  /// 释放内部资源与监听
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupCurrentConnection();
    _scanResultsSub?.cancel();
    _connectionStateController.close();
  }

  /// 监听 App 前后台状态切换
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 如果 App 进入后台，且策略要求不断开，且当前有设备连接，则主动断开
    if ((state == AppLifecycleState.paused || state == AppLifecycleState.hidden) &&
        !keepConnectionInBackground &&
        _activeDevice != null) {
      disconnectActiveDevice();
    }
  }

  /// 开启全局扫描结果监听（保持底层流活跃）
  void _startListeningToScanResults() {
    _scanResultsSub?.cancel();
    _scanResultsSub = FlutterBluePlus.scanResults.listen((_) {});
  }

  /// 清理当前设备的连接状态与内部变量
  void _cleanupCurrentConnection() {
    _connectionStateSub?.cancel();
    _connectionStateSub = null;
    _activeDevice = null;
  }

  /// 检查并请求蓝牙扫描与连接所需的系统权限
  Future<bool> checkAndRequestPermissions() async {
    if (Platform.isAndroid) {
      // 同时请求蓝牙扫描、蓝牙连接和定位权限
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location, // <=== 必须加上定位权限
      ].request();

      // 判断所有必要权限是否都被授予
      final isScanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? true; // Android 11以下可能返回null或默认true
      final isConnectGranted = statuses[Permission.bluetoothConnect]?.isGranted ?? true;
      final isLocationGranted = statuses[Permission.location]?.isGranted ?? false;

      // 兼容不同Android版本的判断
      return (isScanGranted && isConnectGranted) || isLocationGranted;
    } else if (Platform.isIOS) {
      final status = await Permission.bluetooth.request();
      return status.isGranted;
    }
    return true;
  }

  /// 启动蓝牙扫描
  /// [targetChipType] 目标芯片类型筛选（预留参数）
  /// [timeout] 扫描超时时间，默认 15 秒
  Future<void> startScan({required String targetChipType, Duration timeout = const Duration(seconds: 15)}) async {
    if (!(await checkAndRequestPermissions())) throw Exception("未获得蓝牙权限");
    if (FlutterBluePlus.isScanningNow) await FlutterBluePlus.stopScan();
    await FlutterBluePlus.startScan(timeout: timeout);
  }

  /// 停止蓝牙扫描
  Future<void> stopScan() async {
    if (FlutterBluePlus.isScanningNow) await FlutterBluePlus.stopScan();
  }

  /// 连接指定的蓝牙设备并协商 MTU
  /// [device] 需要连接的目标设备实例
  Future<bool> connectToDevice(BluetoothDevice device) async {
    if (_activeDevice != null) {
      await disconnectActiveDevice();
    }

    if (device.isConnected) {
      try {
        await device.disconnect();
      } catch (_) {}
    }
    _connectionSessionId++;
    final currentSession = _connectionSessionId;

    _activeDevice = device;
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      if (Platform.isAndroid) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      await device.discoverServices();
      _connectionStateSub?.cancel();
      _connectionStateSub = device.connectionState.listen((state) {
        _connectionStateController.add(state);
        if (state == BluetoothConnectionState.disconnected && currentSession == _connectionSessionId) {
          _cleanupCurrentConnection();
        }
      });

      if (Platform.isAndroid) {
        try {
          await device.requestMtu(512);
        } catch (e) {
          debugPrint("MTU 请求异常: $e");
        }
      }
      return true;
    } catch (e) {
      debugPrint("设备连接异常: $e");
      if (currentSession == _connectionSessionId) {
        _cleanupCurrentConnection();
      }
      return false;
    }
  }

  /// 主动断开当前已连接的设备
  Future<void> disconnectActiveDevice() async {
    if (_activeDevice == null) return;

    final sessionAtDisconnect = _connectionSessionId; // 记录发起断开时的会话 ID
    try {
      await _activeDevice!.disconnect();
    } catch (e) {
      debugPrint("主动断开异常: $e");
    } finally {
      // 4. 核心拦截：只有当期间没有新的连接发起时，才真正清空 _activeDevice
      if (sessionAtDisconnect == _connectionSessionId) {
        _cleanupCurrentConnection();
      }
    }
  }

  /// 取消订阅通知，释放底层特征值监听资源
  Future<void> unsubscribeFromNotifications({required String deviceId}) async {
    try {
      if (_activeDevice == null || _activeDevice!.remoteId.str != deviceId) return;

      final characteristic = await _findCharacteristicDynamically(deviceId, 'notify');
      if (characteristic.isNotifying) {
        await characteristic.setNotifyValue(false);
        debugPrint("已成功取消蓝牙特征值订阅: $deviceId");
      }
    } catch (e) {
      debugPrint("取消订阅通知异常: $e");
    }
  }

  // 动态查找设备的特征值通道
  // [deviceId] 设备 MAC/ID
  // [type] 通道类型：'write' (写入) 或 'notify' (通知)
  // [defaultWriteUuid] 默认写入特征值 UUID 后缀过滤
  // [defaultNotifyUuid] 默认通知特征值 UUID 后缀过滤
  Future<BluetoothCharacteristic> _findCharacteristicDynamically(
    String deviceId,
    String type, {
    String defaultWriteUuid = "ff03",
    String defaultNotifyUuid = "ff02",
  }) async {
    if (_activeDevice == null || _activeDevice!.remoteId.str != deviceId) {
      throw Exception("设备未连接: $deviceId");
    }

    List<BluetoothService> services = _activeDevice!.servicesList;
    if (services.isEmpty) services = await _activeDevice!.discoverServices();

    for (final service in services) {
      for (final c in service.characteristics) {
        if (type == 'write' &&
            (c.properties.writeWithoutResponse || c.properties.write) &&
            c.uuid.str.toLowerCase().contains(defaultWriteUuid)) {
          return c;
        } else if (type == 'notify' &&
            (c.properties.notify || c.properties.indicate) &&
            c.uuid.str.toLowerCase().contains(defaultNotifyUuid)) {
          return c;
        }
      }
    }
    throw Exception("未找到匹配的特征值通道");
  }

  /// 向设备发送（写入）字节数据
  /// [deviceId] 目标设备 ID
  /// [data] 待发送的字节数组
  Future<void> writeData({required String deviceId, required List<int> data}) async {
    final characteristic = await _findCharacteristicDynamically(deviceId, 'write');
    await characteristic.write(data, withoutResponse: characteristic.properties.writeWithoutResponse);
  }

  /// 订阅设备的消息通知，获取数据流
  /// [deviceId] 目标设备 ID
  Future<Stream<List<int>>> subscribeToNotifications({required String deviceId}) async {
    final characteristic = await _findCharacteristicDynamically(deviceId, 'notify');
    if (!characteristic.isNotifying) {
      await characteristic.setNotifyValue(true);
    }
    return characteristic.onValueReceived;
  }
}
