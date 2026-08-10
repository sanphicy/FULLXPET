import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/core/bluetooth/bluetooth_manager.dart';
import 'package:fullxpet/locator.dart';
import 'models/discovered_device.dart';

class FactoryDebugLog {
  final DateTime timestamp;
  final bool isTx;
  final String rawText;
  final Map<String, dynamic>? parsedJson;

  FactoryDebugLog({required this.timestamp, required this.isTx, required this.rawText, this.parsedJson});
}

class FactoryDebugProvider extends BaseProvider {
  final BluetoothManager _bleManager = locator<BluetoothManager>();

  static const String targetServiceUuid = "0000fa00-0000-1000-8000-00805f9b34fb";
  static const String targetNotifyUuid = "0000fa01-0000-1000-8000-00805f9b34fb";
  static const String targetWriteUuid = "0000fa02-0000-1000-8000-00805f9b34fb";

  DiscoveredDevice? _targetDevice;
  BluetoothDevice? get connectedDevice => _targetDevice?.device;

  BluetoothCharacteristic? _notifyCharacteristic;
  BluetoothCharacteristic? _writeCharacteristic;
  StreamSubscription<List<int>>? _notifySub;

  final StringBuffer _rxBuffer = StringBuffer();
  final List<FactoryDebugLog> _logs = [];
  List<FactoryDebugLog> get logs => List.unmodifiable(_logs);

  bool _isPaused = false;
  bool get isPaused => _isPaused;

  @override
  void dispose() {
    _safeDisconnectAndRelease();
    super.dispose();
  }

  // ==========================================
  // 连接与特征值权限智能遍历 / 降级兜底
  // ==========================================
  Future<bool> connectAndInitGatt(DiscoveredDevice target) async {
    _targetDevice = target;
    setLoading(true);
    clearError();

    try {
      final device = target.device;
      if (device == null) throw Exception("设备句柄为空");

      // 1. 建立 GATT 连接
      final connected = await _bleManager.connectToDevice(device);
      if (!connected) throw Exception("GATT 连接建立失败");

      // 2. 服务发现
      List<BluetoothService> services = await device.discoverServices();
      _notifyCharacteristic = null;
      _writeCharacteristic = null;

      BluetoothService? targetService;
      for (var s in services) {
        if (s.uuid.toString().toLowerCase() == targetServiceUuid) {
          targetService = s;
          break;
        }
      }

      final searchScope = targetService != null ? [targetService] : services;

      // 3. 匹配 Notify 特征值 (优先 0xFA01)
      for (var s in searchScope) {
        for (var c in s.characteristics) {
          if (c.uuid.toString().toLowerCase() == targetNotifyUuid && (c.properties.notify || c.properties.indicate)) {
            _notifyCharacteristic = c;
            break;
          }
        }
      }
      if (_notifyCharacteristic == null) {
        for (var s in services) {
          for (var c in s.characteristics) {
            if (c.properties.notify || c.properties.indicate) {
              _notifyCharacteristic = c;
              break;
            }
          }
          if (_notifyCharacteristic != null) break;
        }
      }

      // 4. 匹配 Write 特征值 (优先 0xFA02)
      for (var s in searchScope) {
        for (var c in s.characteristics) {
          if (c.uuid.toString().toLowerCase() == targetWriteUuid &&
              (c.properties.write || c.properties.writeWithoutResponse)) {
            _writeCharacteristic = c;
            break;
          }
        }
      }
      if (_writeCharacteristic == null) {
        for (var s in services) {
          for (var c in s.characteristics) {
            if (c.properties.write || c.properties.writeWithoutResponse) {
              _writeCharacteristic = c;
              break;
            }
          }
          if (_writeCharacteristic != null) break;
        }
      }

      if (_notifyCharacteristic == null) {
        throw Exception("未找到任何具备 Notify 权限的特征值");
      }

      // 5. 开启订阅
      await _notifyCharacteristic!.setNotifyValue(true);
      _notifySub?.cancel();
      _notifySub = _notifyCharacteristic!.onValueReceived.listen(_handleIncomingBytes);

      setLoading(false);
      return true;
    } catch (e) {
      await _safeDisconnectAndRelease();
      setError("初始化失败: $e");
      setLoading(false);
      return false;
    }
  }

  // ==========================================
  // 流式分包拼接与 JSON 解析
  // ==========================================
  void _handleIncomingBytes(List<int> bytes) {
    if (bytes.isEmpty || _isPaused) return;

    try {
      final chunk = utf8.decode(bytes, allowMalformed: true);
      _rxBuffer.write(chunk);
      final currentString = _rxBuffer.toString().trim();

      if (currentString.endsWith('}')) {
        try {
          final dynamic parsed = jsonDecode(currentString);
          if (parsed is Map<String, dynamic>) {
            _addLog(
              FactoryDebugLog(timestamp: DateTime.now(), isTx: false, rawText: currentString, parsedJson: parsed),
            );
            _rxBuffer.clear();
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint("流解码异常: $e");
    }
  }

  // ==========================================
  // 下发 JSON 指令
  // ==========================================
  Future<bool> sendJsonCommand(String jsonText) async {
    if (_writeCharacteristic == null) {
      setError("未找到可写入的 Write 特征值");
      return false;
    }

    try {
      final dynamic parsed = jsonDecode(jsonText);
      final List<int> bytes = utf8.encode(jsonText);

      await _writeCharacteristic!.write(bytes, withoutResponse: _writeCharacteristic!.properties.writeWithoutResponse);

      _addLog(
        FactoryDebugLog(
          timestamp: DateTime.now(),
          isTx: true,
          rawText: jsonText,
          parsedJson: parsed is Map<String, dynamic> ? parsed : null,
        ),
      );
      return true;
    } catch (e) {
      setError("指令发送失败: $e");
      return false;
    }
  }

  // ==========================================
  // 生命周期安全释放
  // ==========================================
  Future<void> _safeDisconnectAndRelease() async {
    _notifySub?.cancel();
    _notifySub = null;

    if (_notifyCharacteristic != null) {
      try {
        await _notifyCharacteristic!.setNotifyValue(false);
      } catch (_) {}
      _notifyCharacteristic = null;
    }
    _writeCharacteristic = null;

    if (_targetDevice?.device != null) {
      try {
        await _bleManager.disconnectActiveDevice();
      } catch (_) {}
    }
    _rxBuffer.clear();
  }

  void togglePause() {
    _isPaused = !_isPaused;
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    _rxBuffer.clear();
    notifyListeners();
  }

  void _addLog(FactoryDebugLog log) {
    _logs.insert(0, log);
    if (_logs.length > 200) _logs.removeLast();
    notifyListeners();
  }
}
