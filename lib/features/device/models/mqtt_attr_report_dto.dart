import 'package:fullxpet/core/utils/json_parse_ext.dart';

class MqttAttrReportDto {
  final String type;
  final String deviceId;
  final String productId;
  final Map<String, dynamic> functionalAttributes;
  final Map<String, dynamic> changedAttributes;
  final String mqttTopic;
  final int? at;

  const MqttAttrReportDto({
    required this.type,
    required this.deviceId,
    this.productId = '',
    this.functionalAttributes = const {},
    this.changedAttributes = const {},
    this.mqttTopic = '',
    this.at,
  });

  factory MqttAttrReportDto.fromJson(Map<String, dynamic> json) {
    return MqttAttrReportDto(
      type: json.getStr('type'),
      deviceId: json.getStr('deviceId'),
      productId: json.getStr('productId'),
      functionalAttributes: json.getMap('functionalAttributes') ?? const {},
      changedAttributes: json.getMap('changedAttributes') ?? const {},
      mqttTopic: json.getStr('mqttTopic'),
      at: json.getNullableInt('at'),
    );
  }

  /// 取出本次 MQTT 真正变更的 {dpid: value} 字典，直接用来覆盖仓库底表
  Map<String, dynamic> get effectiveChanges => {...functionalAttributes, ...changedAttributes};
}
