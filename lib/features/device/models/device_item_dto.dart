import 'package:fullxpet/features/device/models/advanced_features_dto.dart';
import 'package:fullxpet/core/utils/json_parse_ext.dart';

class DeviceItemDto {
  final String deviceId;
  final String pgDeviceId;
  final String productId;
  final String panelCode;
  final String miniAppId;
  final String category;
  final String panelVersion;
  final String transportProtocol;
  final AdvancedFeaturesDto advancedFeatures;
  final String hardwareId;
  final String nickname;
  final String? iconCode;
  final String iconUrl;
  final bool online;
  final String accessSource;
  final String homeId;
  final String homeName;
  final String roomId;
  final String roomName;
  final int sortOrder;
  final String? shareId;
  final String? sharerUserId;
  final String? shareStatus;
  final bool canView;
  final bool canControl;
  final bool canManage;
  final bool canShare;

  const DeviceItemDto({
    required this.deviceId,
    this.pgDeviceId = '',
    required this.productId,
    this.panelCode = '',
    this.miniAppId = '',
    this.category = '',
    this.panelVersion = '',
    this.transportProtocol = '',
    this.advancedFeatures = const AdvancedFeaturesDto(),
    this.hardwareId = '',
    this.nickname = '',
    this.iconCode,
    this.iconUrl = '',
    this.online = false,
    this.accessSource = '',
    this.homeId = '',
    this.homeName = '',
    this.roomId = '',
    this.roomName = '',
    this.sortOrder = 0,
    this.shareId,
    this.sharerUserId,
    this.shareStatus,
    this.canView = false,
    this.canControl = false,
    this.canManage = false,
    this.canShare = false,
  });

  factory DeviceItemDto.fromJson(Map json) {
    final advMap = json.getMap('advancedFeatures');

    return DeviceItemDto(
      deviceId: json.getStr('deviceId'),
      pgDeviceId: json.getStr('pgDeviceId'),
      productId: json.getStr('productId'),
      panelCode: json.getStr('panelCode'),
      miniAppId: json.getStr('miniAppId'),
      category: json.getStr('category'),
      panelVersion: json.getStr('panelVersion'),
      transportProtocol: json.getStr('transportProtocol'),
      advancedFeatures: advMap != null ? AdvancedFeaturesDto.fromJson(advMap) : const AdvancedFeaturesDto(),
      hardwareId: json.getStr('hardwareId'),
      nickname: json.getStr('nickname'),
      iconCode: json.getNullableStr('iconCode'),
      iconUrl: json.getStr('iconUrl'),
      online: json.getBool('online'),
      accessSource: json.getStr('accessSource', defaultValue: 'HOME_MEMBER'),
      homeId: json.getStr('homeId'),
      homeName: json.getStr('homeName'),
      roomId: json.getStr('roomId'),
      roomName: json.getStr('roomName'),
      sortOrder: json.getInt('sortOrder'),
      shareId: json.getNullableStr('shareId'),
      sharerUserId: json.getNullableStr('sharerUserId'),
      shareStatus: json.getNullableStr('shareStatus'),
      canView: json.getBool('canView', defaultValue: true),
      canControl: json.getBool('canControl', defaultValue: true),
      canManage: json.getBool('canManage', defaultValue: true),
      canShare: json.getBool('canShare', defaultValue: true),
    );
  }

  /// 供仓库底表 2 在重命名、在线状态变更时快速生成新副本
  DeviceItemDto copyWith({String? nickname, bool? online, String? roomId, String? roomName, int? sortOrder}) {
    return DeviceItemDto(
      deviceId: deviceId,
      pgDeviceId: pgDeviceId,
      productId: productId,
      panelCode: panelCode,
      miniAppId: miniAppId,
      category: category,
      panelVersion: panelVersion,
      transportProtocol: transportProtocol,
      advancedFeatures: advancedFeatures,
      hardwareId: hardwareId,
      nickname: nickname ?? this.nickname,
      iconCode: iconCode,
      iconUrl: iconUrl,
      online: online ?? this.online,
      accessSource: accessSource,
      homeId: homeId,
      homeName: homeName,
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      sortOrder: sortOrder ?? this.sortOrder,
      shareId: shareId,
      sharerUserId: sharerUserId,
      shareStatus: shareStatus,
      canView: canView,
      canControl: canControl,
      canManage: canManage,
      canShare: canShare,
    );
  }

  Map toJson() {
    return {
      'deviceId': deviceId,
      'pgDeviceId': pgDeviceId,
      'productId': productId,
      'panelCode': panelCode,
      'miniAppId': miniAppId,
      'category': category,
      'panelVersion': panelVersion,
      'transportProtocol': transportProtocol,
      'advancedFeatures': advancedFeatures.toJson(),
      'hardwareId': hardwareId,
      'nickname': nickname,
      'iconCode': iconCode,
      'iconUrl': iconUrl,
      'online': online,
      'accessSource': accessSource,
      'homeId': homeId,
      'homeName': homeName,
      'roomId': roomId,
      'roomName': roomName,
      'sortOrder': sortOrder,
      'shareId': shareId,
      'sharerUserId': sharerUserId,
      'shareStatus': shareStatus,
      'canView': canView,
      'canControl': canControl,
      'canManage': canManage,
      'canShare': canShare,
    };
  }
}
