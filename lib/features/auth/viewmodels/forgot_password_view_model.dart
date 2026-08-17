import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/core/services/region_service.dart';
import 'package:fullxpet/core/result/result_model.dart';
import 'package:fullxpet/features/auth/models/auth_request.dart';
import 'package:fullxpet/features/auth/repositories/auth_repository.dart';
import 'package:fullxpet/locator.dart';
import 'package:fullxpet/common/models/country_dto.dart';

class ForgotPasswordViewModel extends BaseProvider {
  final AuthRepository _authRepo = locator<AuthRepository>();
  final RegionService _regionService = locator<RegionService>();

  CountryDto? get currentCountry => _regionService.currentCountry;

  Future<void> switchCountry(CountryDto country) async {
    // 立即通知 UI 乐观渲染新选中的国家
    notifyListeners();

    // 后台异步执行 BaseURL 切换与缓存
    final success = await _regionService.switchCountry(country);
    if (!success) {
      // 若失败则重绘回退
      notifyListeners();
    }
  }

  Future<int> sendVerifyCode(String account, bool isPhoneMode) async {
    if (account.trim().isEmpty) {
      setError("请输入账号");
      return 0;
    }
    ResultEntity<int> result;
    if (isPhoneMode) {
      final phonePrefix = currentCountry?.phoneCountryCode ?? "+86";
      result = await _authRepo.sendPhoneVerifyCode(
        SendPhoneCodeRequest(phoneCountryCode: phonePrefix, phone: account, purpose: "reset_password"),
      );
    } else {
      result = await _authRepo.sendEmailVerifyCode(SendEmailCodeRequest(email: account, purpose: "reset_password"));
    }
    if (result.data != null && result.data! > 0) {
      return result.data!;
    } else {
      setError(result.message);
      return 0;
    }
  }

  Future<bool> resetPassword({
    required String account,
    required String newPassword,
    required String code,
    required bool isPhoneMode,
  }) async {
    if (account.trim().isEmpty || newPassword.trim().isEmpty || code.trim().isEmpty) {
      setError("请填写完整信息");
      return false;
    }
    setLoading(true);
    clearError();

    final phonePrefix = currentCountry?.phoneCountryCode ?? "+86";
    ResultEntity<bool> result;
    if (isPhoneMode) {
      result = await _authRepo.resetPasswordByPhone(
        ResetPasswordByPhoneRequest(
          phoneCountryCode: phonePrefix,
          phone: account,
          newPassword: newPassword,
          verificationCode: code,
        ),
      );
    } else {
      result = await _authRepo.resetPassword(
        ResetPasswordRequest(email: account, newPassword: newPassword, verificationCode: code),
      );
    }

    setLoading(false);
    if (result.data == true) {
      return true;
    } else {
      setError(result.message);
      return false;
    }
  }
}
