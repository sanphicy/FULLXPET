import 'package:dio/dio.dart';
import 'package:fullxpet/common/models/user_dto.dart';
import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/core/network/api_client.dart';
import 'package:fullxpet/core/network/api_endpoints.dart';
import 'package:fullxpet/core/network/api_exception.dart';
import 'package:fullxpet/core/services/nav_service.dart';
import 'package:fullxpet/core/storage/token_manager.dart';
import 'package:fullxpet/features/device/repositories/device_repository.dart';
import 'package:fullxpet/locator.dart';
import 'package:fullxpet/routes/app_router.dart';

class UserProvider extends BaseProvider {
  UserDto _user = const UserDto();
  UserDto get user => _user;

  final Dio _dio = locator<ApiClient>().dio;

  // 手动更新全局用户数据
  void updateUser(UserDto newUser) {
    _user = newUser;
    notifyListeners();
  }

  // 获取或静默拉取全局用户信息
  Future<void> fetchUserInfo({bool isSilent = false}) async {
    if (!isSilent && _user.userId.isEmpty) {
      setLoading(true);
    }
    try {
      final res = await _dio.get(ApiEndpoints.userInfo);
      if (res.data is Map<String, dynamic>) {
        _user = UserDto.fromJson(res.data as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (e) {
      final err = ApiException.from(e);
      if (err.code != null && err.code.toString().startsWith('401')) {
        await logout();
      } else if (!isSilent) {
        setError(err.message);
      }
    } finally {
      if (isLoading) setLoading(false);
    }
  }

  // 全局退出登录并清理状态
  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } catch (_) {
    } finally {
      locator<DeviceRepository>().clearPool();
      await TokenManager.clearToken();
      _user = const UserDto();
      NavService.go(AppRoutes.login);
    }
  }
}
