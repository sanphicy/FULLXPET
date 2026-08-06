import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// 蓝牙设备模型
class DiscoveredDevice {
  final String id;
  final String name;
  final int rssi;
  final BluetoothDevice? device;

  DiscoveredDevice({required this.id, required this.name, required this.rssi, this.device});
}
