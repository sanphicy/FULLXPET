import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/core/services/nav_service.dart';
import 'package:fullxpet/core/network/api_endpoints.dart';
import 'package:fullxpet/core/network/http_client.dart';
import 'package:fullxpet/core/storage/token_manager.dart';
import 'package:fullxpet/features/auth/models/auth_request.dart';
import 'package:fullxpet/features/device/repositories/device_repository.dart';
import 'package:fullxpet/locator.dart';
import 'package:fullxpet/routes/app_router.dart';
import 'package:fullxpet/features/auth/repositories/auth_repository.dart';
import 'package:fullxpet/core/network/result_model.dart';

class UserProvider extends BaseProvider {
  String _userName = '';
  String _userId = '-';
  String _avatarUrl = '';
  String _countryCode = '';
  String _timezone = '';
  String _account = '';
  String _appVersion = '';

  String get userName => _userName;
  String get userId => _userId;
  String get avatarUrl => _avatarUrl;
  String get countryCode => _countryCode;
  String get timezone => _timezone;
  String get account => _account;
  String get appVersion => _appVersion;

  final AuthRepository _authRepo = locator<AuthRepository>();

  // 获取用户信息
  Future<void> fetchUserInfo({bool isSilent = false}) async {
    fetchAppVersion();

    if (!isSilent && _userId == '-') {
      setLoading(true);
    }
    try {
      final result = await locator<HttpClient>().get<Map<String, dynamic>>(ApiEndpoints.userInfo);
      if (result.data != null && (result.code == 0 || result.code == 200)) {
        final data = result.data!;
        final newName = data['nickname']?.toString() ?? '';
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
        if (_userName != newName ||
            _userId != newId ||
            _account != newAccount ||
            _avatarUrl != newAvatar ||
            _countryCode != newCountryCode ||
            _timezone != newTimezone) {
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
        setError("获取用户信息失败: $e");
      }
    } finally {
      if (isLoading) setLoading(false);
    }
  }

  // 获取应用版本号
  Future<void> fetchAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
      notifyListeners();
    } catch (_) {
      _appVersion = '-';
      notifyListeners();
    }
  }

  // 更新用户昵称
  Future<bool> updateNickname(String newName) async {
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty || trimmedName == _userName) return false;

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
      setError("修改昵称失败:$e");
    } finally {
      setLoading(false);
    }
    return false;
  }

  // 上传用户头像
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
      setError("头像上传失败，请检查相机/相册权限及网络连接");
    } finally {
      setLoading(false);
    }
    return false;
  }

  // 退出登录
  Future<void> logout() async {
    try {
      await locator<HttpClient>().post<Map<String, dynamic>>(ApiEndpoints.logout);
    } catch (_) {
    } finally {
      locator<DeviceRepository>().clearPool();
      await TokenManager.clearToken();
      _userName = '';
      _userId = '-';
      _avatarUrl = '';
      _countryCode = '';
      _timezone = '';
      _account = '';
      NavService.go(AppRoutes.login);
    }
  }

  // 发送注销验证码（自动判断手机号/邮箱）
  Future<int> sendDeleteAccountCode() async {
    if (_account.isEmpty) {
      setError("未获取到当前账号");
      return 0;
    }
    final bool isEmail = _account.contains('@');
    ResultEntity<int> result;

    if (isEmail) {
      result = await _authRepo.sendEmailVerifyCode(SendEmailCodeRequest(email: _account, purpose: "delete_account"));
    } else {
      final phonePrefix = "+86";
      // final phonePrefix = _countryCode.isNotEmpty ? "+$_countryCode" : "+86";
      result = await _authRepo.sendPhoneVerifyCode(
        SendPhoneCodeRequest(phoneCountryCode: phonePrefix, phone: _account, purpose: "delete_account"),
      );
    }

    if (result.data != null && result.data! > 0) {
      return result.data!;
    } else {
      setError(result.message);
      return 0;
    }
  }

  /// 执行注销账号
  Future<bool> deleteAccount(String code) async {
    if (code.trim().isEmpty) {
      setError("请输入验证码");
      return false;
    }
    setLoading(true);
    clearError();
    try {
      final bool isEmail = _account.contains('@');
      final channel = isEmail ? "email" : "sms";

      final result = await _authRepo.deleteAccount(DeleteAccountRequest(channel: channel, verificationCode: code));

      if (result.data == true) {
        await logout();
        return true;
      } else {
        setError(result.message);
        return false;
      }
    } catch (_) {
      setError("注销失败，请稍后重试");
      return false;
    } finally {
      setLoading(false);
    }
  }
}
