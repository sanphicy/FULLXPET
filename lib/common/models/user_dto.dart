class UserDto {
  final String userId;
  final String nickname;
  final String avatarUrl;
  final String countryCode;
  final String timezone;
  final String email;
  final String phone;
  final String account;
  final String phoneCountryCode;

  // 国内版 默认使用上海时区与CN编码
  const UserDto({
    this.userId = '',
    this.nickname = '',
    this.avatarUrl = '',
    this.countryCode = 'CN',
    this.timezone = 'Asia/Shanghai',
    this.email = '',
    this.phone = '',
    this.account = '',
    this.phoneCountryCode = '+86',
  });

  /// 从后端接口返回的 Map 构造实例
  factory UserDto.fromJson(Map<String, dynamic> json) {
    final emailStr = json['email']?.toString() ?? '';
    final phoneStr = json['phone']?.toString() ?? '';

    // 自动计算当前展示账号（优先邮箱，其次手机号）
    String accountStr = json['account']?.toString() ?? '';
    if (accountStr.isEmpty) {
      accountStr = emailStr.isNotEmpty ? emailStr : phoneStr;
    }

    return UserDto(
      userId: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? json['username']?.toString() ?? '',
      avatarUrl: json['avatarDisplay']?.toString() ?? json['avatar']?.toString() ?? '',
      countryCode: json['countryCode']?.toString() ?? 'CN',
      timezone: json['timezone']?.toString() ?? 'Asia/Shanghai',
      email: emailStr,
      phone: phoneStr,
      account: accountStr,
      phoneCountryCode: json['phoneCountryCode']?.toString() ?? '+86',
    );
  }

  /// 转换为 Map
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'countryCode': countryCode,
      'timezone': timezone,
      'email': email,
      'phone': phone,
      'account': account,
      'phoneCountryCode': phoneCountryCode,
    };
  }

  /// 局部属性修改生成新对象
  UserDto copyWith({
    String? userId,
    String? nickname,
    String? avatarUrl,
    String? countryCode,
    String? timezone,
    String? email,
    String? phone,
    String? account,
    String? phoneCountryCode,
  }) {
    return UserDto(
      userId: userId ?? this.userId,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      countryCode: countryCode ?? this.countryCode,
      timezone: timezone ?? this.timezone,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      account: account ?? this.account,
      phoneCountryCode: phoneCountryCode ?? this.phoneCountryCode,
    );
  }
}
