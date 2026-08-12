import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fullxpet/core/network/api_endpoints.dart';
import 'package:fullxpet/core/network/http_client.dart';
import 'package:fullxpet/core/result/result_model.dart';
import 'package:fullxpet/core/utils/token_manager.dart';
import 'package:fullxpet/locator.dart';
import 'package:fullxpet/features/auth/models/auth_request.dart';
import 'package:fullxpet/common/models/country_dto.dart';

class AuthRepository {
  final HttpClient _httpClient = locator<HttpClient>();

  static const String _countryCacheKey = 'cache_country_list';

  // ================= 获取国家列表 (带缓存) =================
  Future<List<CountryDto>> getCountryList() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 尝试读取本地缓存
    final cachedData = prefs.getString(_countryCacheKey);
    if (cachedData != null && cachedData.isNotEmpty) {
      try {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        return jsonList.map((e) => CountryDto.fromJson(e)).toList();
      } catch (e) {
        debugPrint("解析本地国家列表缓存失败: $e");
      }
    }

    // 2. 如果本地没有缓存，则请求 API
    try {
      final response = await _httpClient.get<Map<String, dynamic>>(
        ApiEndpoints.countries,
        query: {
          'locale': 'zh-CN', // 可以根据手机系统语言动态获取，这里先写死中文测试
          'clientAppId': 'stellapets',
        },
      );

      if (response.data != null && (response.code == 0 || response.code == 200)) {
        final List<dynamic> items = response.data!['items'] ?? [];
        final List<CountryDto> countries = items.map((e) => CountryDto.fromJson(e)).toList();

        // 3. 获取成功后，异步保存到本地缓存
        prefs.setString(_countryCacheKey, jsonEncode(items));

        return countries;
      }
    } catch (e) {
      debugPrint("请求国家列表API失败: $e");
    }

    return [];
  }

  // ================= 现有的 Auth 业务逻辑 =================

  Future<ResultEntity<bool>> loginByphone(PhoneLoginRequest request) async {
    final response = await _httpClient.post<Map<String, dynamic>>(ApiEndpoints.loginByPhone, data: request.toJson());
    if (response.data != null && (response.code == 0 || response.code == 200)) {
      final accessToken = response.data!['accessToken'] as String?;
      if (accessToken != null && accessToken.isNotEmpty) {
        await TokenManager.setToken(accessToken);
        return ResultEntity.success(true);
      } else {
        return ResultEntity.error("登录失败，未获取到 Token");
      }
    }
    return ResultEntity.error(response.message);
  }

  Future<ResultEntity<bool>> loginByEmail(EmailLoginRequest request) async {
    final response = await _httpClient.post<Map<String, dynamic>>(ApiEndpoints.loginByEmail, data: request.toJson());
    if (response.data != null && (response.code == 0 || response.code == 200)) {
      final accessToken = response.data!['accessToken'] as String?;
      if (accessToken != null && accessToken.isNotEmpty) {
        await TokenManager.setToken(accessToken);
        return ResultEntity.success(true);
      } else {
        return ResultEntity.error("登录失败，未获取到 Token");
      }
    }
    return ResultEntity.error(response.message);
  }

  Future<ResultEntity<bool>> sendVerifyCode(SendCodeRequest request) async {
    debugPrint("==== [API Mock] Sent verify code to: ${request.email} (${request.type}) ====");
    return ResultEntity.success(true);
  }

  Future<ResultEntity<bool>> register(RegisterRequest request) async {
    final response = await _httpClient.post<Map<String, dynamic>>(ApiEndpoints.registerByEmail, data: request.toJson());
    if (response.data != null && (response.code == 0 || response.code == 200)) {
      final accessToken = response.data!['accessToken'] as String?;
      if (accessToken != null && accessToken.isNotEmpty) {
        await TokenManager.setToken(accessToken);
        return ResultEntity.success(true);
      } else {
        return ResultEntity.error("注册失败，未获取到 Token");
      }
    }
    return ResultEntity.error(response.message);
  }

  Future<ResultEntity<bool>> resetPassword(ResetPasswordRequest request) async {
    final response = await _httpClient.post<Map<String, dynamic>>(ApiEndpoints.resetPassword, data: request.toJson());
    if (response.code == 0 || response.code == 200) {
      return ResultEntity.success(true);
    }
    return ResultEntity.error(response.message);
  }

  Future<ResultEntity<bool>> resetPasswordByPhone(ResetPasswordByPhoneRequest request) async {
    final response = await _httpClient.post<Map<String, dynamic>>(
      ApiEndpoints.resetPasswordByPhone,
      data: request.toJson(),
    );
    if (response.code == 0 || response.code == 200) {
      return ResultEntity.success(true);
    }
    return ResultEntity.error(response.message);
  }

  //根据电话号码注册
  Future<ResultEntity<bool>> registerByPhone(PhoneRegisterRequest request) async {
    final response = await _httpClient.post<Map<String, dynamic>>(ApiEndpoints.registerByPhone, data: request.toJson());
    if (response.data != null && (response.code == 0 || response.code == 200)) {
      final accessToken = response.data!['accessToken'] as String?;
      if (accessToken != null && accessToken.isNotEmpty) {
        await TokenManager.setToken(accessToken);
        return ResultEntity.success(true);
      }
    }
    return ResultEntity.error(response.message);
  }

  // 发送手机验证码
  Future<ResultEntity<int>> sendPhoneVerifyCode(SendPhoneCodeRequest request) async {
    final response = await _httpClient.post<Map<String, dynamic>>(ApiEndpoints.phoneCode, data: request.toJson());

    if (response.data != null && (response.code == 0 || response.code == 200)) {
      final cooldown = response.data!['cooldownSeconds'] as int? ?? 60;
      return ResultEntity.success(cooldown);
    }
    return ResultEntity.error(response.message);
  }

  // 发送邮箱验证码
  Future<ResultEntity<int>> sendEmailVerifyCode(SendEmailCodeRequest request) async {
    final response = await _httpClient.post<Map<String, dynamic>>(ApiEndpoints.emailCode, data: request.toJson());

    if (response.data != null && (response.code == 0 || response.code == 200)) {
      final cooldown = response.data!['cooldownSeconds'] as int? ?? 60;
      return ResultEntity.success(cooldown);
    }
    return ResultEntity.error(response.message);
  }
}
