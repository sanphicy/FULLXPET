import 'package:fullxpet/core/utils/json_parse_ext.dart';

/// 猫砂盆日志事件类型
enum DeviceLogType { executeAction, catEntry, catToilet, calibration, resetWifi }

// 设备日志
class DeviceLog {
  final DateTime time;
  final DeviceLogType type;
  final String content;

  const DeviceLog({required this.time, required this.type, this.content = ''});

  bool get isCatEvent => type == DeviceLogType.catEntry || type == DeviceLogType.catToilet;
}

/// 日志原始 DP 值项
class DeviceLogRawValue {
  final String dpid;
  final dynamic value;

  const DeviceLogRawValue({required this.dpid, this.value});

  factory DeviceLogRawValue.fromJson(Map json) {
    return DeviceLogRawValue(dpid: json.getStr('dpid'), value: json['value']);
  }
}

/// 日志原始时间点记录
class DeviceLogRawItem {
  final String ts;
  final List<DeviceLogRawValue> values;

  const DeviceLogRawItem({required this.ts, this.values = const []});

  factory DeviceLogRawItem.fromJson(Map json) {
    final rawValues = json.getList('values');
    return DeviceLogRawItem(
      ts: json.getStr('ts'),
      values: [
        for (final v in rawValues)
          if (v is Map) DeviceLogRawValue.fromJson(v),
      ],
    );
  }
}

/// 设备属性日志分页响应 DTO
class DeviceLogPageDto {
  final List<DeviceLogRawItem> items;
  final int pageSize;
  final String? nextPageToken;
  final bool hasMore;

  const DeviceLogPageDto({this.items = const [], this.pageSize = 20, this.nextPageToken, this.hasMore = false});

  factory DeviceLogPageDto.fromJson(Map json) {
    final rawItems = json.getList('items');
    final token = json.getNullableStr('nextPageToken');
    return DeviceLogPageDto(
      items: [
        for (final item in rawItems)
          if (item is Map) DeviceLogRawItem.fromJson(item),
      ],
      pageSize: json.getInt('pageSize', defaultValue: 20),
      nextPageToken: token,
      hasMore: json.getBool('hasMore') && token != null && token.isNotEmpty,
    );
  }
}
