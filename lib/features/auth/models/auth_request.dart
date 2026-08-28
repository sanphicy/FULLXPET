// 手机号码登录请求
class PhoneLoginRequest {
  final String phoneCountryCode;
  final String phone;
  final String password;

  const PhoneLoginRequest({required this.phoneCountryCode, required this.phone, required this.password});

  Map<String, dynamic> toJson() => {
    "phoneCountryCode": phoneCountryCode,
    "phone": phone.trim(),
    "password": password.trim(),
  };
}

// 邮箱密码登录请求
class EmailLoginRequest {
  final String email;
  final String password;

  const EmailLoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {"email": email.trim(), "password": password.trim()};
}

// 邮箱注册请求
class RegisterRequest {
  final String email;
  final String password;
  final String verificationCode;
  final String countryCode;

  const RegisterRequest({
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

// 手机号注册请求
class PhoneRegisterRequest {
  final String phoneCountryCode;
  final String phone;
  final String password;
  final String verificationCode;
  final String countryCode;

  const PhoneRegisterRequest({
    required this.phoneCountryCode,
    required this.phone,
    required this.password,
    required this.verificationCode,
    required this.countryCode,
  });

  Map<String, dynamic> toJson() => {
    "phoneCountryCode": phoneCountryCode.trim(),
    "phone": phone.trim(),
    "password": password.trim(),
    "verificationCode": verificationCode.trim(),
    "countryCode": countryCode.trim(),
  };
}

// 邮箱重置密码请求
class ResetPasswordRequest {
  final String email;
  final String newPassword;
  final String verificationCode;

  const ResetPasswordRequest({required this.email, required this.newPassword, required this.verificationCode});

  Map<String, dynamic> toJson() => {
    "email": email.trim(),
    "newPassword": newPassword.trim(),
    "verificationCode": verificationCode.trim(),
  };
}

// 手机号重置密码请求
class ResetPasswordByPhoneRequest {
  final String phoneCountryCode;
  final String phone;
  final String newPassword;
  final String verificationCode;

  const ResetPasswordByPhoneRequest({
    required this.phoneCountryCode,
    required this.phone,
    required this.newPassword,
    required this.verificationCode,
  });

  Map<String, dynamic> toJson() => {
    "phoneCountryCode": phoneCountryCode.trim(),
    "phone": phone.trim(),
    "newPassword": newPassword.trim(),
    "verificationCode": verificationCode.trim(),
  };
}

// 发送手机验证码请求
class SendPhoneCodeRequest {
  final String phoneCountryCode;
  final String phone;
  final String purpose;

  const SendPhoneCodeRequest({required this.phoneCountryCode, required this.phone, required this.purpose});

  Map<String, dynamic> toJson() => {
    "phoneCountryCode": phoneCountryCode.trim(),
    "phone": phone.trim(),
    "purpose": purpose,
  };
}

// 发送邮箱验证码请求
class SendEmailCodeRequest {
  final String email;
  final String purpose;

  const SendEmailCodeRequest({required this.email, required this.purpose});

  Map<String, dynamic> toJson() => {"email": email.trim(), "purpose": purpose};
}

// 注销账号请求
class DeleteAccountRequest {
  final String channel;
  final String verificationCode;

  const DeleteAccountRequest({required this.channel, required this.verificationCode});

  Map<String, dynamic> toJson() => {"channel": channel.trim(), "verificationCode": verificationCode.trim()};
}
