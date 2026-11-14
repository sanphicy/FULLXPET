class FeederLiveInfo {
  final String appId;
  final String channelName;
  final int uid;
  final String token;
  final int expiresAt;
  final String role;
  final bool deviceLiveConfigPushed;
  final String deviceLiveRefreshStatus;

  const FeederLiveInfo({
    required this.appId,
    required this.channelName,
    required this.uid,
    required this.token,
    this.expiresAt = 0,
    this.role = 'publisher',
    this.deviceLiveConfigPushed = false,
    this.deviceLiveRefreshStatus = '',
  });

  bool get isValid => appId.isNotEmpty && channelName.isNotEmpty && token.isNotEmpty;

  factory FeederLiveInfo.fromJson(Map<String, dynamic> json) {
    return FeederLiveInfo(
      appId: json['appId']?.toString() ?? '',
      channelName: json['channelName']?.toString() ?? '',
      uid: int.tryParse(json['uid']?.toString() ?? '') ?? 0,
      token: json['token']?.toString() ?? '',
      expiresAt: int.tryParse(json['expiresAt']?.toString() ?? '') ?? 0,
      role: json['role']?.toString() ?? 'publisher',
      deviceLiveConfigPushed: json['deviceLiveConfigPushed'] == true,
      deviceLiveRefreshStatus: json['deviceLiveRefreshStatus']?.toString() ?? '',
    );
  }
}
