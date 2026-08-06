import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  static late String _accessTokenKey;
  static const _storage = FlutterSecureStorage();
  static String? _cachedAccessToken;

  static void init({required String accessKey}) {
    _accessTokenKey = accessKey;
  }

  // 保存 Token
  static Future<void> setToken(String accessToken) async {
    _cachedAccessToken = accessToken;
    await _storage.write(key: _accessTokenKey, value: accessToken);
  }

  // 获取 Token
  static Future<String?> getAccessToken() async {
    _cachedAccessToken ??= await _storage.read(key: _accessTokenKey);
    return _cachedAccessToken;
  }

  // 清除 Token
  static Future<void> clearToken() async {
    _cachedAccessToken = null;
    await _storage.delete(key: _accessTokenKey);
  }

  // 判断是否登录
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
