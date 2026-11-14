import 'package:fullxpet/core/utils/json_parse_ext.dart';
import 'device_hardware_info.dart';

class DevicePropertiesDto {
  final String deviceId;
  final String productId;
  final bool online;
  final String connectionStatus;
  final int? lastAttrReportAt;
  final DeviceHardwareInfo deviceInfo;
  final List<DeviceAttributeDto> attributes;

  const DevicePropertiesDto({
    required this.deviceId,
    this.productId = '',
    this.online = false,
    this.connectionStatus = 'OFFLINE',
    this.lastAttrReportAt,
    this.deviceInfo = const DeviceHardwareInfo(),
    this.attributes = const [],
  });

  factory DevicePropertiesDto.fromJson(Map json) {
    final rawAttrs = json.getList('attributes');
    final infoMap = json.getMap('deviceInfo');

    final parsedList = [
      for (final item in rawAttrs)
        if (item is Map) DeviceAttributeDto.fromJson(item.cast()),
    ];

    return DevicePropertiesDto(
      deviceId: json.getStr('deviceId'),
      productId: json.getStr('productId'),
      online: json.getBool('online'),
      connectionStatus: json.getStr('connectionStatus', defaultValue: 'OFFLINE'),
      lastAttrReportAt: json.getNullableInt('lastAttrReportAt'),
      deviceInfo: infoMap != null ? DeviceHardwareInfo.fromJson(infoMap) : const DeviceHardwareInfo(),
      attributes: parsedList,
    );
  }

  /// 核心方法：一键把 attributes 数组拍平，变成仓库底表直接存的 Map<dpid, value>
  Map<String, dynamic> toDpidMap() {
    final Map<String, dynamic> map = {};
    for (final attr in attributes) {
      if (attr.dpid.isNotEmpty) {
        map[attr.dpid] = attr.normalizedValue;
      }
    }
    return map;
  }
}

/// 单个 DPID 功能点的通用接收盒（所有设备格式完全一样）
class DeviceAttributeDto {
  final String dpid;
  final String name;
  final String type;
  final String access;
  final dynamic value;
  final int? updatedAt;

  const DeviceAttributeDto({
    required this.dpid,
    this.name = '',
    this.type = 'string',
    this.access = 'rw',
    this.value,
    this.updatedAt,
  });

  factory DeviceAttributeDto.fromJson(Map<String, dynamic> json) {
    return DeviceAttributeDto(
      dpid: json.getStr('dpid'),
      name: json.getStr('name'),
      type: json.getStr('type', defaultValue: 'string'),
      access: json.getStr('access', defaultValue: 'rw'),
      value: json['value'],
      updatedAt: json.getNullableInt('updatedAt'),
    );
  }

  /// 自动根据 type 把字符串 "0" 还原成数字 0，把 "true" 还原成 bool true
  dynamic get normalizedValue {
    if (value == null) return null;
    switch (type.toLowerCase()) {
      case 'int':
      case 'value':
      case 'enum':
        if (value is int) return value;
        if (value is num) return (value as num).toInt();
        return int.tryParse(value.toString()) ?? 0;
      case 'bool':
        if (value is bool) return value;
        final str = value.toString().toLowerCase();
        return str == 'true' || str == '1';
      default:
        return value;
    }
  }
}
