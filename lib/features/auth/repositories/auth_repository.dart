import 'package:fullxpet/core/network/api_endpoints.dart';
import 'package:fullxpet/core/network/http_client.dart';
import 'package:fullxpet/core/network/result_model.dart';
import 'package:fullxpet/core/storage/token_manager.dart';
import 'package:fullxpet/locator.dart';
import 'package:fullxpet/features/auth/models/auth_request.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/core/services/nav_service.dart';
import 'package:flutter/material.dart';

class AuthRepository {
  final HttpClient _httpClient = locator<HttpClient>();

  String get _tokenParseErrorMsg {
    final BuildContext? ctx = NavService.rootNavigatorKey.currentContext;
    if (ctx != null) {
      final s = S.of(ctx);
      if (s != null) {
        return s.tokenParseError;
      }
    }
    return "登录凭证解析失败，请重试";
  }

  //手机号登录
  Future<ResultEntity<bool>> loginByPhone(PhoneLoginRequest request) async {
    final response = await _httpClient.post<Map<String, dynamic>>(ApiEndpoints.loginByPhone, data: request.toJson());
    if (response.data != null && (response.code == 0 || response.code == 200)) {
      final accessToken = response.data!['accessToken'] as String?;
      if (accessToken != null && accessToken.isNotEmpty) {
        await TokenManager.setToken(accessToken);
        return ResultEntity.success(true);
      }
      return ResultEntity.error(_tokenParseErrorMsg);
    }
    return ResultEntity.error(response.message);
  }

  //邮箱登录
  Future<ResultEntity<bool>> loginByEmail(EmailLoginRequest request) async {
    final response = await _httpClient.post<Map<String, dynamic>>(ApiEndpoints.loginByEmail, data: request.toJson());
    if (response.data != null && (response.code == 0 || response.code == 200)) {
      final accessToken = response.data!['accessToken'] as String?;
      if (accessToken != null && accessToken.isNotEmpty) {
        await TokenManager.setToken(accessToken);
        return ResultEntity.success(true);
      }
      return ResultEntity.error(_tokenParseErrorMsg);
    }
    return ResultEntity.error(response.message);
  }

  //手机号注册
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

  //邮箱注册
  Future<ResultEntity<bool>> registerByEmail(RegisterRequest request) async {
    final response = await _httpClient.post<Map<String, dynamic>>(ApiEndpoints.registerByEmail, data: request.toJson());
    if (response.data != null && (response.code == 0 || response.code == 200)) {
      final accessToken = response.data!['accessToken'] as String?;
      if (accessToken != null && accessToken.isNotEmpty) {
        await TokenManager.setToken(accessToken);
        return ResultEntity.success(true);
      }
    }
    return ResultEntity.error(response.message);
  }

  //邮箱找回密码
  Future<ResultEntity<bool>> resetPasswordByEmail(ResetPasswordRequest request) async {
    final response = await _httpClient.post<Map<String, dynamic>>(ApiEndpoints.resetPassword, data: request.toJson());
    if (response.code == 0 || response.code == 200) {
      return ResultEntity.success(true);
    }
    return ResultEntity.error(response.message);
  }

  //手机号找回密码
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

  //手机号发送验证码
  Future<ResultEntity<int>> sendPhoneVerifyCode(SendPhoneCodeRequest request) async {
    final response = await _httpClient.post<Map<String, dynamic>>(ApiEndpoints.phoneCode, data: request.toJson());
    if (response.data != null && (response.code == 0 || response.code == 200)) {
      final cooldown = response.data!['cooldownSeconds'] as int? ?? 60;
      return ResultEntity.success(cooldown);
    }
    return ResultEntity.error(response.message);
  }

  //邮箱发送验证码
  Future<ResultEntity<int>> sendEmailVerifyCode(SendEmailCodeRequest request) async {
    final response = await _httpClient.post<Map<String, dynamic>>(ApiEndpoints.emailCode, data: request.toJson());
    if (response.data != null && (response.code == 0 || response.code == 200)) {
      final cooldown = response.data!['cooldownSeconds'] as int? ?? 60;
      return ResultEntity.success(cooldown);
    }
    return ResultEntity.error(response.message);
  }

  //注销账号
  Future<ResultEntity<bool>> deleteAccount(DeleteAccountRequest request) async {
    final response = await _httpClient.post<Map<String, dynamic>>(ApiEndpoints.deleteAccount, data: request.toJson());
    if (response.code == 0 || response.code == 200) {
      return ResultEntity.success(true);
    }
    return ResultEntity.error(response.message);
  }
}
