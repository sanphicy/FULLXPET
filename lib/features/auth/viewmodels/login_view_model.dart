import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/core/services/region_service.dart';
import 'package:fullxpet/core/network/api_exception.dart';
import 'package:fullxpet/features/auth/models/auth_request.dart';
import 'package:fullxpet/features/auth/repositories/auth_repository.dart';
import 'package:fullxpet/locator.dart';
import 'package:fullxpet/common/models/country_dto.dart';

class LoginViewModel extends BaseProvider {
  final AuthRepository _authRepo = locator<AuthRepository>();
  final RegionService _regionService = locator<RegionService>();

  CountryDto? get currentCountry => _regionService.currentCountry;

  Future<void> switchCountry(CountryDto country) async {
    final success = await _regionService.switchCountry(country);
    if (!success) {
      notifyListeners();
    }
  }

  Future<bool> login(String account, String password, {required bool isEmail}) async {
    if (account.trim().isEmpty || password.trim().isEmpty) {
      setError("账号或密码不能为空");
      return false;
    }
    setLoading(true);
    clearError();

    try {
      bool success = false;
      if (isEmail) {
        success = await _authRepo.loginByEmail(EmailLoginRequest(email: account, password: password));
      } else {
        final phonePrefix = currentCountry?.phoneCountryCode ?? "+86";
        success = await _authRepo.loginByPhone(
          PhoneLoginRequest(phoneCountryCode: phonePrefix, phone: account, password: password),
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
