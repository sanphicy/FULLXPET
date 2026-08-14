import 'package:fullxpet/core/network/api_endpoints.dart';
import 'package:fullxpet/core/network/http_client.dart';
import 'package:fullxpet/core/result/result_model.dart';
import 'package:fullxpet/core/utils/token_manager.dart';
import 'package:fullxpet/locator.dart';
import 'package:fullxpet/features/auth/models/auth_request.dart';

class AuthRepository {
  final HttpClient _httpClient = locator<HttpClient>();

  Future<ResultEntity<bool>> loginByPhone(PhoneLoginRequest request) async {
    final response = await _httpClient.post<Map<String, dynamic>>(ApiEndpoints.loginByPhone, data: request.toJson());
    if (response.data != null && (response.code == 0 || response.code == 200)) {
      final accessToken = response.data!['accessToken'] as String?;
      if (accessToken != null && accessToken.isNotEmpty) {
        await TokenManager.setToken(accessToken);
        return ResultEntity.success(true);
      }
      return ResultEntity.error("Invalid Token");
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
      }
      return ResultEntity.error("Invalid Token");
    }
    return ResultEntity.error(response.message);
  }

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

  Future<ResultEntity<int>> sendPhoneVerifyCode(SendPhoneCodeRequest request) async {
    final response = await _httpClient.post<Map<String, dynamic>>(ApiEndpoints.phoneCode, data: request.toJson());
    if (response.data != null && (response.code == 0 || response.code == 200)) {
      final cooldown = response.data!['cooldownSeconds'] as int? ?? 60;
      return ResultEntity.success(cooldown);
    }
    return ResultEntity.error(response.message);
  }

  Future<ResultEntity<int>> sendEmailVerifyCode(SendEmailCodeRequest request) async {
    final response = await _httpClient.post<Map<String, dynamic>>(ApiEndpoints.emailCode, data: request.toJson());
    if (response.data != null && (response.code == 0 || response.code == 200)) {
      final cooldown = response.data!['cooldownSeconds'] as int? ?? 60;
      return ResultEntity.success(cooldown);
    }
    return ResultEntity.error(response.message);
  }
}
