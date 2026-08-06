import 'package:dio/dio.dart';
import 'package:fullxpet/locator.dart';
import 'package:fullxpet/routes/app_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fullxpet/core/network/http_client.dart';
import 'package:fullxpet/core/utils/token_manager.dart';
import 'package:fullxpet/core/network/api_endpoints.dart';
import 'package:fullxpet/core/navigation/nav_service.dart';
import 'package:fullxpet/common/providers/base_provider.dart';

class UserProvider extends BaseProvider {
  String _userName = 'Unknown User';
  String _userId = '-';
  String _avatarUrl = '';
  String _countryCode = '';
  String _timezone = '';

  int _catCount = 0;
  int _dayCount = 0;
  int _deviceCount = 0;

  // Getters
  String get userName => _userName;
  String get userId => _userId;
  String get avatarUrl => _avatarUrl;
  String get countryCode => _countryCode;
  String get timezone => _timezone;
  int get catCount => _catCount;
  int get dayCount => _dayCount;
  int get deviceCount => _deviceCount;

  // 拉取用户信息
  // isSilent 为 true 时，不展示加载动画，且不向上抛出阻断性错误 用于冷启动/后台切入
  Future<void> fetchUserInfo({bool isSilent = false}) async {
    final isLoggedIn = await TokenManager.isLoggedIn();
    if (!isLoggedIn) {
      await logout();
      return;
    }

    // 只有在非静默请求，且当前内存中确实没有数据时，才展示 Loading
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
        if (_userName != newName || _userId != newId) {
          _userName = newName;
          _userId = newId;
          _avatarUrl = newAvatar;
          _countryCode = newCountryCode;
          _timezone = newTimezone;
          notifyListeners();
        }
      } else if (result.code == 401) {
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

  //修改用户昵称
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

  // 上传并更新用户头像
  Future<bool> uploadAvatar(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80, // 压缩质量
        maxWidth: 800,
      );

      if (image == null) return false; // 用户取消选择

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

  // 登出
  Future<void> logout() async {
    try {
      await locator<HttpClient>().post<Map<String, dynamic>>(ApiEndpoints.logout);
    } catch (_) {
      // 忽略登出时的网络错误
    } finally {
      await TokenManager.clearToken();
      _userName = 'Unknown User';
      _userId = '-';
      NavService.go(AppRoutes.login);
    }
  }
}
