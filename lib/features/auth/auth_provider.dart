import 'package:flutter/material.dart';
import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/locator.dart';
import 'package:fullxpet/core/result/result_model.dart';
import 'package:fullxpet/features/auth/models/auth_request.dart';
import 'package:fullxpet/features/auth/repositories/auth_repository.dart';
import 'package:fullxpet/common/models/country_dto.dart';

class LoginProvider extends BaseProvider {
  final AuthRepository _authRepo = locator<AuthRepository>();

  // ================= 国家列表状态管理 =================
  List<CountryDto> _countryList = [];
  List<CountryDto> get countryList => _countryList;

  CountryDto? _selectedCountry;
  CountryDto? get selectedCountry => _selectedCountry;

  Future<void> fetchCountries() async {
    // 如果内存中已经有数据，直接返回，避免重复渲染
    if (_countryList.isNotEmpty) return;

    try {
      _countryList = await _authRepo.getCountryList();
      if (_countryList.isNotEmpty) {
        // 默认选中中国，如果没有则选中列表第一项
        _selectedCountry = _countryList.firstWhere((c) => c.countryCode == 'CN', orElse: () => _countryList.first);
      }
      notifyListeners();
    } catch (e) {
      debugPrint("获取国家列表失败: $e");
    }
  }

  void selectCountry(CountryDto country) {
    _selectedCountry = country;
    notifyListeners();
  }

  // ================= 原有业务逻辑 =================

  Future<bool> login(String account, String password, {required bool isEmail}) async {
    if (account.trim().isEmpty || password.trim().isEmpty) {
      setError("Please fill in all fields");
      return false;
    }
    setLoading(true);
    clearError();
    ResultEntity<bool> result;

    if (isEmail) {
      final request = EmailLoginRequest(email: account, password: password);
      result = await _authRepo.loginByEmail(request);
    } else {
      final request = PhoneLoginRequest(phoneCountryCode: "+86", phone: account, password: password);
      result = await _authRepo.loginByphone(request);
    }

    if (isLoading) setLoading(false);

    if (result.data == true) {
      return true;
    } else {
      setError(result.message);
      return false;
    }
  }

  // 返回 int，代表冷却时间（秒）
  Future<int> sendVerifyCode(String account, String type, {required String purpose}) async {
    if (account.trim().isEmpty) {
      setError("账号不能为空");
      return 0;
    }

    ResultEntity<int> result;

    if (type == "Email") {
      result = await _authRepo.sendEmailVerifyCode(SendEmailCodeRequest(email: account, purpose: purpose));
    } else {
      final currentPhoneCode = _selectedCountry?.phoneCountryCode ?? "+86";
      result = await _authRepo.sendPhoneVerifyCode(
        SendPhoneCodeRequest(phoneCountryCode: currentPhoneCode, phone: account, purpose: purpose),
      );
    }

    if (result.data != null && result.data! > 0) {
      return result.data!;
    } else {
      setError(result.message);
      return 0;
    }
  }

  Future<bool> register({
    required String account,
    required String password,
    required String code,
    required String countryCode,
    required bool isPhoneMode,
    String phoneCountryCode = "+86",
  }) async {
    if (account.trim().isEmpty || password.trim().isEmpty || code.trim().isEmpty) {
      setError("Please fill in all fields");
      return false;
    }

    setLoading(true);
    clearError();
    ResultEntity<bool> result;

    if (isPhoneMode) {
      // 手机号注册逻辑
      final request = PhoneRegisterRequest(
        phoneCountryCode: phoneCountryCode,
        phone: account,
        password: password,
        verificationCode: code,
      );
      result = await _authRepo.registerByPhone(request);
    } else {
      // 邮箱注册逻辑
      final request = RegisterRequest(
        email: account,
        password: password,
        verificationCode: code,
        countryCode: countryCode,
      );
      result = await _authRepo.register(request);
    }

    if (isLoading) setLoading(false);
    if (result.data == true) {
      return true;
    } else {
      setError(result.message);
      return false;
    }
  }

  Future<bool> resetPassword(String email, String newPassword, String code) async {
    if (email.trim().isEmpty || newPassword.trim().isEmpty || code.trim().isEmpty) {
      setError("Please fill in all fields");
      return false;
    }
    final result = await _authRepo.resetPassword(
      ResetPasswordRequest(email: email, newPassword: newPassword, verificationCode: code),
    );
    if (result.data == true) {
      return true;
    } else {
      setError(result.message);
      return false;
    }
  }
}
