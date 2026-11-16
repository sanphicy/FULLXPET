import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/core/services/region_service.dart';
import 'package:fullxpet/core/network/api_exception.dart';
import 'package:fullxpet/features/auth/models/auth_request.dart';
import 'package:fullxpet/features/auth/repositories/auth_repository.dart';
import 'package:fullxpet/locator.dart';
import 'package:fullxpet/common/models/country_dto.dart';

class RegisterViewModel extends BaseProvider {
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
          SendPhoneCodeRequest(phoneCountryCode: phonePrefix, phone: account, purpose: "register"),
        );
      } else {
        cooldown = await _authRepo.sendEmailVerifyCode(SendEmailCodeRequest(email: account, purpose: "register"));
      }
      return cooldown;
    } catch (e) {
      setError(ApiException.from(e).message);
      return 0;
    }
  }

  Future<bool> register({
    required String account,
    required String password,
    required String code,
    required bool isPhoneMode,
  }) async {
    if (account.trim().isEmpty || password.trim().isEmpty || code.trim().isEmpty) {
      setError("请填写完整信息");
      return false;
    }
    setLoading(true);
    clearError();

    try {
      final countryCode = currentCountry?.countryCode ?? "CN";
      final phonePrefix = currentCountry?.phoneCountryCode ?? "+86";
      bool success = false;

      if (isPhoneMode) {
        success = await _authRepo.registerByPhone(
          PhoneRegisterRequest(
            phoneCountryCode: phonePrefix,
            phone: account,
            password: password,
            verificationCode: code,
            countryCode: countryCode,
          ),
        );
      } else {
        success = await _authRepo.registerByEmail(
          RegisterRequest(email: account, password: password, verificationCode: code, countryCode: countryCode),
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
