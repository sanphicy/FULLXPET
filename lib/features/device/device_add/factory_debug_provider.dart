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

  // 🌟 核心修复：根据项目的配网协议，明确使用 FF02 和 FF03
  static const String targetNotifyUuidPartial = "ff02";
  static const String targetWriteUuidPartial = "ff03";

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

      // 强制停止扫描，防止信道冲突
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
      _notifyCharacteristic = null;
      _writeCharacteristic = null;

      // 🌟 核心修复：精准匹配 FF02 和 FF03，不匹配绝不随意兜底
      for (var s in services) {
        for (var c in s.characteristics) {
          final uuidStr = c.uuid.toString().toLowerCase();

          // 匹配 Notify
          if ((c.properties.notify || c.properties.indicate) &&
              (uuidStr.contains(targetNotifyUuidPartial) || uuidStr.contains("fa01"))) {
            _notifyCharacteristic = c;
          }

          // 匹配 Write
          if ((c.properties.write || c.properties.writeWithoutResponse) &&
              (uuidStr.contains(targetWriteUuidPartial) || uuidStr.contains("fa02"))) {
            _writeCharacteristic = c;
          }
        }
      }

      if (_notifyCharacteristic == null) {
        throw Exception("找不到对应的 Notify 特征值 (FF02/FA01)");
      }
      if (_writeCharacteristic == null) {
        throw Exception("找不到对应的 Write 特征值 (FF03/FA02)");
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
  // 处理接收到的字节流 (滑动窗口容错解析)
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
              _addLog(
                FactoryDebugLog(
                  timestamp: DateTime.now(),
                  isTx: false,
                  rawText: potentialJson,
                  parsedJson: finalJsonMap,
                ),
              );
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
  // 清理
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
    notifyListeners();
  }

  void _addLog(FactoryDebugLog log) {
    _logs.insert(0, log);
    if (_logs.length > 200) _logs.removeLast();
    notifyListeners();
  }
}
