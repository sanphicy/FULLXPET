import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/core/services/region_service.dart';
import 'package:fullxpet/core/network/result_model.dart';
import 'package:fullxpet/features/auth/models/auth_request.dart';
import 'package:fullxpet/features/auth/repositories/auth_repository.dart';
import 'package:fullxpet/locator.dart';
import 'package:fullxpet/common/models/country_dto.dart';

class LoginViewModel extends BaseProvider {
  final AuthRepository _authRepo = locator<AuthRepository>();
  final RegionService _regionService = locator<RegionService>();

  CountryDto? get currentCountry => _regionService.currentCountry;

  // 乐观更新右上角选中国家
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

  //登录
  Future<bool> login(String account, String password, {required bool isEmail}) async {
    if (account.trim().isEmpty || password.trim().isEmpty) {
      setError("请填写完整信息");
      return false;
    }
    setLoading(true);
    clearError();

    ResultEntity<bool> result;
    if (isEmail) {
      result = await _authRepo.loginByEmail(EmailLoginRequest(email: account, password: password));
    } else {
      final phonePrefix = currentCountry?.phoneCountryCode ?? "+86";
      result = await _authRepo.loginByPhone(
        PhoneLoginRequest(phoneCountryCode: phonePrefix, phone: account, password: password),
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
