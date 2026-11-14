import 'dart:convert';
import 'discovered_device.dart';

typedef BlePacket = List<int>;
typedef WifiMap = Map<String, dynamic>;

/// 蓝牙分包与拼包器（根据 ProvisionMode.junvine 或 ProvisionMode.hooget 执行对应格式）
class BlePacketCodec {
  final ProvisionMode mode;

  final List<int> _hoogetBuffer = [];
  int _hoogetExpectedLen = 0;

  int _junvineExpectedTotal = 0;
  final Map<int, BlePacket> _junvinePackets = {};

  BlePacketCodec({required this.mode});

  void reset() {
    _hoogetBuffer.clear();
    _hoogetExpectedLen = 0;
    _junvineExpectedTotal = 0;
    _junvinePackets.clear();
  }

  /// 分包编码
  List<BlePacket> encode(WifiMap jsonMap) {
    final String jsonStr = jsonEncode(jsonMap);
    final List<int> jsonData = utf8.encode(jsonStr);
    final int totalLength = jsonData.length;
    if (totalLength == 0) return [];

    if (mode == ProvisionMode.hooget) {
      if (totalLength > 255) {
        throw Exception("JSON 长度超过 255 字节限制");
      }
      final List<BlePacket> packets = [];
      final int firstPacketDataLen = totalLength > 18 ? 18 : totalLength;
      final List<int> firstPacket = [0x86, totalLength];
      firstPacket.addAll(jsonData.sublist(0, firstPacketDataLen));
      packets.add(firstPacket);

      int offset = firstPacketDataLen;
      while (offset < totalLength) {
        final int remaining = totalLength - offset;
        final int chunkLen = remaining > 20 ? 20 : remaining;
        packets.add(jsonData.sublist(offset, offset + chunkLen));
        offset += chunkLen;
      }
      return packets;
    } else {
      const int chunkSize = 18;
      final int totalPackets = (totalLength / chunkSize).ceil();
      if (totalPackets > 255) {
        throw Exception("数据过长，超过协议支持的 255 个分包限制");
      }

      final List<BlePacket> packets = [];
      for (int i = 0; i < totalPackets; i++) {
        final int start = i * chunkSize;
        final int end = (start + chunkSize < totalLength) ? start + chunkSize : totalLength;
        final List<int> chunkData = jsonData.sublist(start, end);
        packets.add([totalPackets, i + 1, ...chunkData]);
      }
      return packets;
    }
  }

  /// 接收拼包
  List<int>? onReceiveChunk(List<int> value) {
    if (value.isEmpty) return null;

    if (mode == ProvisionMode.hooget) {
      if (_hoogetExpectedLen == 0 && value[0] == 0x86 && value.length >= 2) {
        _hoogetExpectedLen = value[1];
        _hoogetBuffer.clear();
        _hoogetBuffer.addAll(value.sublist(2));
      } else {
        _hoogetBuffer.addAll(value);
      }

      if (_hoogetExpectedLen > 0 && _hoogetBuffer.length >= _hoogetExpectedLen) {
        final validBytes = _hoogetBuffer.sublist(0, _hoogetExpectedLen);
        reset();
        return validBytes;
      }
      return null;
    } else {
      if (value.length < 2) return null;
      final int totalPackets = value[0];
      final int currentPacketIndex = value[1];
      final List<int> payloadData = value.sublist(2);

      if (totalPackets > 0 && currentPacketIndex > 0 && currentPacketIndex <= totalPackets) {
        if (_junvineExpectedTotal == 0) {
          _junvineExpectedTotal = totalPackets;
          _junvinePackets.clear();
        }
        _junvinePackets[currentPacketIndex] = payloadData;

        if (_junvinePackets.length == _junvineExpectedTotal) {
          final List<int> completeBytes = [];
          bool isComplete = true;
          for (int i = 1; i <= _junvineExpectedTotal; i++) {
            if (_junvinePackets.containsKey(i)) {
              completeBytes.addAll(_junvinePackets[i]!);
            } else {
              isComplete = false;
              break;
            }
          }
          reset();
          if (isComplete) return completeBytes;
        }
      }
      return null;
    }
  }
}
