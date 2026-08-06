class UserDto {
  final String userId;
  final String? email;
  final String? phone;
  final String? nickname;

  UserDto({required this.userId, this.email, this.phone, this.nickname});

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (nickname != null) 'nickname': nickname,
    };
  }
}
