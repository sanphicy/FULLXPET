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

  DiscoveredDevice? _targetDevice;
  BluetoothDevice? get connectedDevice => _targetDevice?.device;

  BluetoothCharacteristic? _notifyCharacteristic;
  BluetoothCharacteristic? _writeCharacteristic;

  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<BluetoothConnectionState>? _connSub;

  final StringBuffer _rxBuffer = StringBuffer();
  final List<FactoryDebugLog> _logs = [];

  List<FactoryDebugLog> get logs => List.unmodifiable(_logs);

  bool _isPaused = false;
  bool get isPaused => _isPaused;

  // --- 电机卡死/无动作检测变量 ---
  final List<int> _recentEncoderCounts = []; // 存储运动状态下的编码器脉冲
  bool _isMotorStuckWarning = false; // 是否触发“电机有动作指令但编码器无变化”警告
  bool get isMotorStuckWarning => _isMotorStuckWarning;

  @override
  void dispose() {
    _connSub?.cancel();
    _safeDisconnectAndRelease();
    super.dispose();
  }

  // ==========================================
  // 连接与初始化 GATT
  // ==========================================
  Future<bool> connectAndInitGatt(DiscoveredDevice target) async {
    _targetDevice = target;
    setLoading(true);
    clearError();

    try {
      final device = target.device;
      if (device == null) throw Exception("设备对象为空");

      await _bleManager.stopScan();

      // 1. 连接 GATT
      final connected = await _bleManager.connectToDevice(device);
      if (!connected) throw Exception("GATT 连接失败");

      // 监听断开
      _connSub?.cancel();
      _connSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected && _targetDevice != null && !isLoading) {
          setError("设备蓝牙已断开");
        }
      });

      // 2. 发现服务
      List<BluetoothService> services = await device.discoverServices();

      BluetoothCharacteristic? notifyChrFA01;
      BluetoothCharacteristic? writeChrFA02;
      BluetoothCharacteristic? notifyChrFF02;
      BluetoothCharacteristic? writeChrFF03;

      for (var s in services) {
        for (var c in s.characteristics) {
          final uuidStr = c.uuid.toString().toLowerCase();

          if (uuidStr.contains("fa01") && (c.properties.notify || c.properties.indicate)) {
            notifyChrFA01 = c;
          }
          if (uuidStr.contains("fa02") && (c.properties.write || c.properties.writeWithoutResponse)) {
            writeChrFA02 = c;
          }

          if (uuidStr.contains("ff02") && (c.properties.notify || c.properties.indicate)) {
            notifyChrFF02 = c;
          }
          if (uuidStr.contains("ff03") && (c.properties.write || c.properties.writeWithoutResponse)) {
            writeChrFF03 = c;
          }
        }
      }

      if (notifyChrFA01 != null && writeChrFA02 != null) {
        _notifyCharacteristic = notifyChrFA01;
        _writeCharacteristic = writeChrFA02;
        debugPrint("工厂调试: 成功匹配专属厂测通道 FA01/FA02");
      } else if (notifyChrFF02 != null && writeChrFF03 != null) {
        _notifyCharacteristic = notifyChrFF02;
        _writeCharacteristic = writeChrFF03;
        debugPrint("工厂调试: 启用降级通道 FF02/FF03");
      } else {
        throw Exception("此设备未暴露厂测通道，无法调试。");
      }

      // 3. 开启监听
      await _notifyCharacteristic!.setNotifyValue(true);
      _notifySub?.cancel();
      _notifySub = _notifyCharacteristic!.onValueReceived.listen(_handleIncomingBytes);

      setLoading(false);
      return true;
    } catch (e) {
      await _safeDisconnectAndRelease();
      setError("连接异常: $e");
      setLoading(false);
      return false;
    }
  }

  // ==========================================
  // 处理接收字节流与逻辑检测
  // ==========================================
  void _handleIncomingBytes(List<int> bytes) {
    if (bytes.isEmpty || _isPaused) return;

    try {
      final chunk = utf8.decode(bytes, allowMalformed: true);
      _rxBuffer.write(chunk);
      _processBuffer();
    } catch (e) {
      debugPrint("解析异常: $e");
    }
  }

  void _processBuffer() {
    String currentString = _rxBuffer.toString();
    bool foundValidJson = true;

    while (foundValidJson && currentString.isNotEmpty) {
      foundValidJson = false;

      int startIndex = currentString.indexOf(RegExp(r'[\{\[]'));
      if (startIndex == -1) {
        _rxBuffer.clear();
        break;
      }

      for (int i = startIndex + 1; i <= currentString.length; i++) {
        String potentialJson = currentString.substring(startIndex, i);
        if (potentialJson.endsWith('}') || potentialJson.endsWith(']')) {
          try {
            final dynamic parsed = jsonDecode(potentialJson);
            Map<String, dynamic>? finalJsonMap;
            if (parsed is Map<String, dynamic>) {
              finalJsonMap = parsed;
            } else if (parsed is List) {
              finalJsonMap = {"array_data": parsed};
            }

            if (finalJsonMap != null) {
              // 1. 追加日志
              _addLog(
                FactoryDebugLog(
                  timestamp: DateTime.now(),
                  isTx: false,
                  rawText: potentialJson,
                  parsedJson: finalJsonMap,
                ),
              );

              // 2. 结合“运行状态 + 编码器脉冲”判定电机是否异常卡死
              _checkMotorStuckCondition(finalJsonMap);
            }

            currentString = currentString.substring(i);
            _rxBuffer.clear();
            _rxBuffer.write(currentString);
            foundValidJson = true;
            break;
          } catch (_) {}
        }
      }
    }

    if (_rxBuffer.length > 4096) {
      _rxBuffer.clear();
    }
  }

  /// 准确检测：只有在电机处于“非空闲状态 (state != 0)”时，如果编码器脉冲持续不变化，才报卡死/无动作
  void _checkMotorStuckCondition(Map<String, dynamic>? telemetry) {
    if (telemetry == null) return;

    final motor = telemetry['sensors']?['motor'];
    if (motor == null) return;

    final int state = motor['state'] is num ? (motor['state'] as num).toInt() : 0;
    final int currentEncoder = motor['encoder_cnt'] is num ? (motor['encoder_cnt'] as num).toInt() : 0;

    // 核心逻辑：只有 state != 0 (电机被指令驱动运转中/寻零中) 才需要监测编码器脉冲！
    final bool isMotorWorking = (state != 0);

    if (!isMotorWorking) {
      // 只要电机回到空闲 (state == 0)，无论过载与否、无论脉冲是多少，直接清空计数并关闭黄色提示！
      if (_recentEncoderCounts.isNotEmpty || _isMotorStuckWarning) {
        _recentEncoderCounts.clear();
        _isMotorStuckWarning = false;
        notifyListeners();
      }
      return;
    }

    // 以下只有在 state != 0 (电机正在运转) 时才会执行：
    _recentEncoderCounts.add(currentEncoder);

    if (_recentEncoderCounts.length > 3) {
      _recentEncoderCounts.removeAt(0);
    }

    // 运行状态下，连续 3 次脉冲完全没有变化 -> 判定堵转/无动作
    if (_recentEncoderCounts.length == 3 && _recentEncoderCounts.every((cnt) => cnt == _recentEncoderCounts.first)) {
      if (!_isMotorStuckWarning) {
        _isMotorStuckWarning = true;
        notifyListeners();
      }
    } else {
      if (_isMotorStuckWarning) {
        _isMotorStuckWarning = false;
        notifyListeners();
      }
    }
  }

  // ==========================================
  // 发送指令 (支持纯 JSON 或 0x86 配网协议)
  // ==========================================
  Future<bool> sendJsonCommand(String jsonText, {bool use0x86 = false}) async {
    if (_targetDevice?.device != null && _targetDevice!.device!.isConnected == false) {
      setError("连接已断开，正在尝试重连...");
      bool reconnected = await connectAndInitGatt(_targetDevice!);
      if (!reconnected) {
        return false;
      }
    }

    if (_writeCharacteristic == null) {
      setError("未发现 Write 特征值");
      return false;
    }

    try {
      final dynamic parsed = jsonDecode(jsonText);
      final List<int> jsonData = utf8.encode(jsonText);

      if (use0x86) {
        final int totalLength = jsonData.length;
        if (totalLength > 255) throw Exception("JSON长度超过 255 字节限制");

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
          await _writeCharacteristic!.write(
            packet,
            withoutResponse: _writeCharacteristic!.properties.writeWithoutResponse,
          );
          await Future.delayed(const Duration(milliseconds: 15));
        }
      } else {
        await _writeCharacteristic!.write(
          jsonData,
          withoutResponse: _writeCharacteristic!.properties.writeWithoutResponse,
        );
      }

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
      setError("发送异常: $e");
      return false;
    }
  }

  // ==========================================
  // 资源释放与清理
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
    _targetDevice = null;
    _rxBuffer.clear();
  }

  void togglePause() {
    _isPaused = !_isPaused;
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    _rxBuffer.clear();
    _recentEncoderCounts.clear();
    _isMotorStuckWarning = false;
    notifyListeners();
  }

  void _addLog(FactoryDebugLog log) {
    _logs.insert(0, log);
    if (_logs.length > 200) _logs.removeLast();
    notifyListeners();
  }
}
