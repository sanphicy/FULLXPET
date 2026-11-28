import 'package:image_picker/image_picker.dart';

import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/common/providers/user_provider.dart';
import 'package:fullxpet/core/network/api_exception.dart';
import 'package:fullxpet/features/auth/models/auth_request.dart';
import 'package:fullxpet/features/auth/repositories/auth_repository.dart';
import 'package:fullxpet/features/user/repositories/user_repository.dart';
import 'package:fullxpet/locator.dart';

class UserViewModel extends BaseProvider {
  final UserProvider _userProvider = locator<UserProvider>();
  final AuthRepository _authRepo = locator<AuthRepository>();
  final UserRepository _userRepo = locator<UserRepository>();

  /// 修改昵称
  Future<bool> updateNickname(String newName) async {
    final trimmedName = newName.trim();
    final currentUser = _userProvider.user;
    if (trimmedName.isEmpty || trimmedName == currentUser.nickname) return false;

    setLoading(true);
    clearError();
    try {
      final payload = {
        'nickname': trimmedName,
        'countryCode': currentUser.countryCode,
        'timezone': currentUser.timezone,
      };
      await _userRepo.updateUserInfo(payload);
      _userProvider.updateUser(currentUser.copyWith(nickname: trimmedName));
      return true;
    } catch (e) {
      setError(ApiException.from(e).message);
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// 上传头像
  Future<bool> uploadAvatar(ImageSource source) async {
    final XFile? image;
    try {
      final ImagePicker picker = ImagePicker();
      image = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 800);
    } catch (_) {
      return false;
    }
    if (image == null) return false;

    setLoading(true);
    clearError();
    try {
      final newAvatar = await _userRepo.uploadAvatar(image);
      if (newAvatar != null && newAvatar.isNotEmpty) {
        _userProvider.updateUser(_userProvider.user.copyWith(avatarUrl: newAvatar));
        return true;
      } else {
        setError('头像上传返回数据异常');
        return false;
      }
    } catch (e) {
      setError(ApiException.from(e).message);
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// 发送注销验证码（由弹窗自身承载发送中状态）
  Future<int> sendDeleteAccountCode() async {
    final currentUser = _userProvider.user;
    if (currentUser.account.isEmpty) {
      setError('未获取到当前账号');
      return 0;
    }

    clearError();
    try {
      final bool isEmail = currentUser.account.contains('@');
      final int cooldown;
      if (isEmail) {
        cooldown = await _authRepo.sendEmailVerifyCode(
          SendEmailCodeRequest(email: currentUser.account, purpose: 'delete_account'),
        );
      } else {
        cooldown = await _authRepo.sendPhoneVerifyCode(
          SendPhoneCodeRequest(
            phoneCountryCode: currentUser.phoneCountryCode,
            phone: currentUser.account,
            purpose: 'delete_account',
          ),
        );
      }

      if (cooldown > 0) {
        return cooldown;
      } else {
        setError('发送验证码失败');
        return 0;
      }
    } catch (e) {
      setError(ApiException.from(e).message);
      return 0;
    }
  }

  /// 执行注销账号（由弹窗自身承载提交状态，失败时不关闭弹窗）
  Future<bool> deleteAccount(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      setError('请输入验证码');
      return false;
    }

    clearError();
    try {
      final bool isEmail = _userProvider.user.account.contains('@');
      final channel = isEmail ? 'email' : 'phone';
      await _authRepo.deleteAccount(DeleteAccountRequest(channel: channel, verificationCode: trimmed));
      await _userProvider.logout();
      return true;
    } catch (e) {
      setError(ApiException.from(e).message);
      return false;
    }
  }
}
