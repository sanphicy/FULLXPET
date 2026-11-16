import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/core/services/region_service.dart';
import 'package:fullxpet/core/network/api_exception.dart';
import 'package:fullxpet/features/auth/models/auth_request.dart';
import 'package:fullxpet/features/auth/repositories/auth_repository.dart';
import 'package:fullxpet/locator.dart';
import 'package:fullxpet/common/models/country_dto.dart';

class ForgotPasswordViewModel extends BaseProvider {
  final AuthRepository _authRepo = locator<AuthRepository>();
  final RegionService _regionService = locator<RegionService>();

  CountryDto? get currentCountry => _regionService.currentCountry;

  Future<void> switchCountry(CountryDto country) async {
    final success = await _regionService.switchCountry(country);
    if (!success) {
      notifyListeners();
    }
  }

  Future<int> sendVerifyCode(String account, bool isPhoneMode) async {
    if (account.trim().isEmpty) {
      setError("账号不能为空");
      return 0;
    }
    try {
      int cooldown = 60;
      if (isPhoneMode) {
        final phonePrefix = currentCountry?.phoneCountryCode ?? "+86";
        cooldown = await _authRepo.sendPhoneVerifyCode(
          SendPhoneCodeRequest(phoneCountryCode: phonePrefix, phone: account, purpose: "reset_password"),
        );
      } else {
        cooldown = await _authRepo.sendEmailVerifyCode(SendEmailCodeRequest(email: account, purpose: "reset_password"));
      }
      return cooldown;
    } catch (e) {
      setError(ApiException.from(e).message);
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

    try {
      final phonePrefix = currentCountry?.phoneCountryCode ?? "+86";
      bool success = false;

      if (isPhoneMode) {
        success = await _authRepo.resetPasswordByPhone(
          ResetPasswordByPhoneRequest(
            phoneCountryCode: phonePrefix,
            phone: account,
            newPassword: newPassword,
            verificationCode: code,
          ),
        );
      } else {
        success = await _authRepo.resetPasswordByEmail(
          ResetPasswordRequest(email: account, newPassword: newPassword, verificationCode: code),
        );
      }
      return success;
    } catch (e) {
      setError(ApiException.from(e).message);
      return false;
    } finally {
      setLoading(false);
    }
  }
}
