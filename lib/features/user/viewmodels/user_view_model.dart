import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/common/providers/user_provider.dart';
import 'package:fullxpet/core/network/api_endpoints.dart';
import 'package:fullxpet/core/network/http_client.dart';
import 'package:fullxpet/core/network/result_model.dart';
import 'package:fullxpet/features/auth/models/auth_request.dart';
import 'package:fullxpet/features/auth/repositories/auth_repository.dart';
import 'package:fullxpet/locator.dart';

class UserViewModel extends BaseProvider {
  final UserProvider _userProvider = locator<UserProvider>();
  final AuthRepository _authRepo = locator<AuthRepository>();
  final HttpClient _httpClient = locator<HttpClient>();

  String _appVersion = '';
  String get appVersion => _appVersion;

  UserViewModel() {
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = info.version;
      notifyListeners();
    } catch (_) {}
  }

  // 修改昵称
  Future<bool> updateNickname(String newName) async {
    final trimmedName = newName.trim();
    final currentUser = _userProvider.user;
    if (trimmedName.isEmpty || trimmedName == currentUser.nickname) return false;

    setLoading(true);
    try {
      final payload = {
        "nickname": trimmedName,
        "countryCode": currentUser.countryCode,
        "timezone": currentUser.timezone,
      };
      final result = await _httpClient.patch<Map<String, dynamic>>(ApiEndpoints.userInfo, data: payload);
      if (result.code == 0 || result.code == 200) {
        _userProvider.updateUser(currentUser.copyWith(nickname: trimmedName));
        return true;
      } else {
        setError(result.message);
      }
    } catch (e) {
      setError("修改昵称失败: $e");
    } finally {
      setLoading(false);
    }
    return false;
  }

  // 上传头像
  Future<bool> uploadAvatar(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 800);
      if (image == null) return false;

      setLoading(true);
      final formData = FormData.fromMap({'file': await MultipartFile.fromFile(image.path, filename: image.name)});
      final result = await _httpClient.post<Map<String, dynamic>>(ApiEndpoints.uploadAvatar, data: formData);
      if (result.data != null && (result.code == 0 || result.code == 200)) {
        final data = result.data!;
        final newAvatar = data['avatarDisplay']?.toString() ?? data['avatar']?.toString();
        if (newAvatar != null && newAvatar.isNotEmpty) {
          _userProvider.updateUser(_userProvider.user.copyWith(avatarUrl: newAvatar));
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

  // 发送注销验证码
  Future<int> sendDeleteAccountCode() async {
    final currentUser = _userProvider.user;
    if (currentUser.account.isEmpty) {
      setError("未获取到当前账号");
      return 0;
    }
    final bool isEmail = currentUser.account.contains('@');
    ResultEntity<int> result;

    if (isEmail) {
      result = await _authRepo.sendEmailVerifyCode(
        SendEmailCodeRequest(email: currentUser.account, purpose: "delete_account"),
      );
    } else {
      final phonePrefix = _userProvider.user.phoneCountryCode;
      result = await _authRepo.sendPhoneVerifyCode(
        SendPhoneCodeRequest(phoneCountryCode: phonePrefix, phone: currentUser.account, purpose: "delete_account"),
      );
    }

    if (result.data != null && result.data! > 0) {
      return result.data!;
    } else {
      setError(result.message);
      return 0;
    }
  }

  // 执行注销
  Future<bool> deleteAccount(String code) async {
    if (code.trim().isEmpty) {
      setError("请输入验证码");
      return false;
    }
    setLoading(true);
    clearError();
    try {
      final bool isEmail = _userProvider.user.account.contains('@');
      final channel = isEmail ? "email" : "sms";

      final result = await _authRepo.deleteAccount(DeleteAccountRequest(channel: channel, verificationCode: code));

      if (result.data == true) {
        await _userProvider.logout();
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
