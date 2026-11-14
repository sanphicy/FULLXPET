import 'package:fullxpet/core/utils/json_parse_ext.dart';

class AdvancedFeaturesDto {
  final bool cloudStorage;
  final bool ai;
  final bool ipcStream;
  final bool intercom;
  final String liveMedia;
  final bool subDevice;
  final List<String> childProductIds;

  const AdvancedFeaturesDto({
    this.cloudStorage = false,
    this.ai = false,
    this.ipcStream = false,
    this.intercom = false,
    this.liveMedia = '',
    this.subDevice = false,
    this.childProductIds = const [],
  });

  factory AdvancedFeaturesDto.fromJson(Map<String, dynamic> json) {
    final rawChildProductIds = json['childProductIds'];
    return AdvancedFeaturesDto(
      cloudStorage: json.getBool('cloudStorage'),
      ai: json.getBool('ai'),
      ipcStream: json.getBool('ipcStream'),
      intercom: json.getBool('intercom'),
      liveMedia: json.getStr('liveMedia'),
      subDevice: json.getBool('subDevice'),
      childProductIds: rawChildProductIds is List ? rawChildProductIds.map((e) => e.toString()).toList() : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cloudStorage': cloudStorage,
      'ai': ai,
      'ipcStream': ipcStream,
      'intercom': intercom,
      'liveMedia': liveMedia,
      'subDevice': subDevice,
      'childProductIds': childProductIds,
    };
  }
}
