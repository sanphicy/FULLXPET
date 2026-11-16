import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/core/network/api_client.dart';
import 'package:fullxpet/core/network/api_endpoints.dart';
import 'package:fullxpet/core/storage/token_manager.dart';
import 'package:fullxpet/features/auth/models/auth_request.dart';
import 'package:fullxpet/core/services/nav_service.dart';
import 'package:fullxpet/locator.dart';

class AuthRepository {
  // 严格对齐新网络架构：直接使用 GetIt 获取全局唯一的 Dio 实例
  final Dio _dio = locator<ApiClient>().dio;

  String get _tokenParseErrorMsg {
    final BuildContext? ctx = NavService.rootNavigatorKey.currentContext;
    if (ctx != null) {
      final s = S.of(ctx);
      if (s != null) {
        return s.tokenParseError;
      }
    }
    return "Token 解析失败";
  }

  /// 手机号登录：成功返回 true，并自动持久化 Token
  Future<bool> loginByPhone(PhoneLoginRequest request) async {
    final res = await _dio.post(ApiEndpoints.loginByPhone, data: request.toJson());
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final accessToken = data['accessToken']?.toString();
      if (accessToken != null && accessToken.isNotEmpty) {
        await TokenManager.setToken(accessToken);
        return true;
      }
    }
    throw Exception(_tokenParseErrorMsg);
  }

  /// 邮箱登录：成功返回 true，并自动持久化 Token
  Future<bool> loginByEmail(EmailLoginRequest request) async {
    final res = await _dio.post(ApiEndpoints.loginByEmail, data: request.toJson());
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final accessToken = data['accessToken']?.toString();
      if (accessToken != null && accessToken.isNotEmpty) {
        await TokenManager.setToken(accessToken);
        return true;
      }
    }
    throw Exception(_tokenParseErrorMsg);
  }

  /// 手机号注册：成功返回 true，并自动持久化 Token
  Future<bool> registerByPhone(PhoneRegisterRequest request) async {
    final res = await _dio.post(ApiEndpoints.registerByPhone, data: request.toJson());
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final accessToken = data['accessToken']?.toString();
      if (accessToken != null && accessToken.isNotEmpty) {
        await TokenManager.setToken(accessToken);
        return true;
      }
    }
    return true;
  }

  /// 邮箱注册：成功返回 true，并自动持久化 Token
  Future<bool> registerByEmail(RegisterRequest request) async {
    final res = await _dio.post(ApiEndpoints.registerByEmail, data: request.toJson());
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final accessToken = data['accessToken']?.toString();
      if (accessToken != null && accessToken.isNotEmpty) {
        await TokenManager.setToken(accessToken);
        return true;
      }
    }
    return true;
  }

  /// 重置密码 (邮箱)
  Future<bool> resetPasswordByEmail(ResetPasswordRequest request) async {
    await _dio.post(ApiEndpoints.resetPassword, data: request.toJson());
    return true;
  }

  /// 重置密码 (手机)
  Future<bool> resetPasswordByPhone(ResetPasswordByPhoneRequest request) async {
    await _dio.post(ApiEndpoints.resetPasswordByPhone, data: request.toJson());
    return true;
  }

  /// 发送手机验证码：返回倒计时秒数 (cooldownSeconds)
  Future<int> sendPhoneVerifyCode(SendPhoneCodeRequest request) async {
    final res = await _dio.post(ApiEndpoints.phoneCode, data: request.toJson());
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return int.tryParse(data['cooldownSeconds']?.toString() ?? '') ?? 60;
    }
    return 60;
  }

  /// 发送邮箱验证码：返回倒计时秒数 (cooldownSeconds)
  Future<int> sendEmailVerifyCode(SendEmailCodeRequest request) async {
    final res = await _dio.post(ApiEndpoints.emailCode, data: request.toJson());
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return int.tryParse(data['cooldownSeconds']?.toString() ?? '') ?? 60;
    }
    return 60;
  }

  /// 注销账号
  Future<bool> deleteAccount(DeleteAccountRequest request) async {
    await _dio.post(ApiEndpoints.deleteAccount, data: request.toJson());
    return true;
  }
}
