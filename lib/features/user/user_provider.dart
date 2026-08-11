import 'package:dio/dio.dart';
import 'package:fullxpet/locator.dart';
import 'package:fullxpet/routes/app_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fullxpet/core/network/http_client.dart';
import 'package:fullxpet/core/utils/token_manager.dart';
import 'package:fullxpet/core/network/api_endpoints.dart';
import 'package:fullxpet/core/navigation/nav_service.dart';
import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UserProvider extends BaseProvider {
  String _userName = 'Unknown User';
  String _userId = '-';
  String _avatarUrl = '';
  String _countryCode = '';
  String _timezone = '';
  String _account = ''; // 专门用于存储 邮箱 或 手机号
  String _appVersion = '1.0.0';

  // Getters
  String get userName => _userName;
  String get userId => _userId;
  String get avatarUrl => _avatarUrl;
  String get countryCode => _countryCode;
  String get timezone => _timezone;
  String get account => _account;
  String get appVersion => _appVersion;

  /// 获取用户信息
  Future<void> fetchUserInfo({bool isSilent = false}) async {
    fetchAppVersion();
    final isLoggedIn = await TokenManager.isLoggedIn();
    if (!isLoggedIn) {
      await logout();
      return;
    }

    if (!isSilent && _userId == '-') {
      setLoading(true);
    }
    try {
      final result = await locator<HttpClient>().get<Map<String, dynamic>>(ApiEndpoints.userInfo);
      if (result.data != null && (result.code == 0 || result.code == 200)) {
        final data = result.data!;
        final newName = data['nickname']?.toString() ?? 'Unknown User';
        final newId = data['userId']?.toString() ?? '-';
        final newAvatar = data['avatarDisplay']?.toString() ?? _avatarUrl;
        final newCountryCode = data['countryCode']?.toString() ?? 'CN';
        final newTimezone = data['timezone']?.toString() ?? 'UTC';
        String newAccount = '';
        if (data['email'] != null && data['email'].toString().isNotEmpty) {
          newAccount = data['email'].toString();
        } else if (data['phone'] != null && data['phone'].toString().isNotEmpty) {
          newAccount = data['phone'].toString();
        }
        if (_userName != newName || _userId != newId || _account != newAccount) {
          _userName = newName;
          _userId = newId;
          _avatarUrl = newAvatar;
          _countryCode = newCountryCode;
          _timezone = newTimezone;
          _account = newAccount;
          notifyListeners();
        }
      } else if (result.code == 401 || (result.code != null && result.code.toString().startsWith('401'))) {
        await logout();
      } else if (!isSilent) {
        setError(result.message);
      }
    } catch (e) {
      if (!isSilent) {
        setError("Failed to fetch user data: $e");
      }
    } finally {
      if (isLoading) setLoading(false);
    }
  }

  // 读取应用版本号
  Future<void> fetchAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      notifyListeners();
    } catch (e) {
      _appVersion = '-';
      notifyListeners();
    }
  }

  /// 修改昵称
  Future<bool> updateNickname(String newName) async {
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty || trimmedName == _userName) {
      return false;
    }
    setLoading(true);
    try {
      final payload = {
        "nickname": trimmedName,
        "countryCode": _countryCode.isNotEmpty ? _countryCode : "CN",
        "timezone": _timezone.isNotEmpty ? _timezone : "Asia/Shanghai",
      };
      final result = await locator<HttpClient>().patch<Map<String, dynamic>>(ApiEndpoints.userInfo, data: payload);
      if (result.code == 0 || result.code == 200) {
        _userName = trimmedName;
        notifyListeners();
        return true;
      } else {
        setError(result.message);
      }
    } catch (e) {
      setError("Failed to update nickname: $e");
    } finally {
      setLoading(false);
    }
    return false;
  }

  /// 上传头像
  Future<bool> uploadAvatar(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 800);
      if (image == null) return false;

      setLoading(true);
      final formData = FormData.fromMap({'file': await MultipartFile.fromFile(image.path, filename: image.name)});
      final result = await locator<HttpClient>().post<Map<String, dynamic>>(ApiEndpoints.uploadAvatar, data: formData);
      if (result.data != null && (result.code == 0 || result.code == 200)) {
        final data = result.data!;
        final newAvatar = data['avatarDisplay']?.toString() ?? data['avatar']?.toString();
        if (newAvatar != null && newAvatar.isNotEmpty) {
          _avatarUrl = newAvatar;
          notifyListeners();
          return true;
        }
      } else {
        setError(result.message);
      }
    } catch (e) {
      setError("Avatar upload failed: $e");
    } finally {
      setLoading(false);
    }
    return false;
  }

  /// 退出登录
  Future<void> logout() async {
    try {
      await locator<HttpClient>().post<Map<String, dynamic>>(ApiEndpoints.logout);
    } catch (_) {
    } finally {
      await TokenManager.clearToken();
      _userName = 'Unknown User';
      _userId = '-';
      _account = '';
      NavService.go(AppRoutes.login);
    }
  }
}
