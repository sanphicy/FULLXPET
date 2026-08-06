//手机号码登录
class PhoneLoginRequest {
  final String phoneCountryCode;
  final String phone;
  final String password;

  PhoneLoginRequest({
    required this.phoneCountryCode,
    required this.phone,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    "phoneCountryCode": phoneCountryCode,
    "phone": phone.trim(),
    "password": password.trim(),
  };
}

/// 邮箱密码登录请求
class EmailLoginRequest {
  final String email;
  final String password;

  EmailLoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
    "email": email.trim(),
    "password": password.trim(),
  };
}

/// 注册请求模型
class RegisterRequest {
  final String email;
  final String password;
  final String verificationCode;
  final String countryCode;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.verificationCode,
    required this.countryCode,
  });

  Map<String, dynamic> toJson() => {
    "email": email.trim(),
    "password": password.trim(),
    "verificationCode": verificationCode.trim(),
    "countryCode": countryCode.trim(),
  };
}

/// 重置密码请求模型
class ResetPasswordRequest {
  final String email;
  final String newPassword;
  final String verificationCode;

  ResetPasswordRequest({
    required this.email,
    required this.newPassword,
    required this.verificationCode,
  });

  Map<String, dynamic> toJson() => {
    "email": email.trim(),
    "newPassword": newPassword.trim(),
    "code": verificationCode.trim(),
  };
}

/// 发送验证码请求模型
class SendCodeRequest {
  final String email;
  final String type;

  SendCodeRequest({required this.email, required this.type});

  Map<String, dynamic> toJson() => {"email": email.trim(), "type": type};
}
