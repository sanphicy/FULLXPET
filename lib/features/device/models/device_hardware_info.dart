import 'package:fullxpet/core/utils/json_parse_ext.dart';

//设备硬件信息DTO
class DeviceHardwareInfo {
  final String rssi;
  final String channel;
  final String wifiVersion;
  final String mcuVersion;
  final String imei;
  final String ssid;

  const DeviceHardwareInfo({
    this.rssi = '',
    this.channel = '',
    this.wifiVersion = '',
    this.mcuVersion = '',
    this.imei = '',
    this.ssid = '',
  });

  factory DeviceHardwareInfo.fromJson(Map<String, dynamic> json) {
    return DeviceHardwareInfo(
      rssi: json.getStr('rssi'),
      channel: json.getStr('ch'),
      wifiVersion: json.getStr('wifiVersion'),
      mcuVersion: json.getStr('mcuVersion'),
      imei: json.getStr('imei'),
      ssid: json.getStr('ssid'),
    );
  }
}
