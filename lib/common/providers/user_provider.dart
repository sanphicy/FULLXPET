import 'package:fullxpet/common/models/user_dto.dart';
import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/core/network/api_endpoints.dart';
import 'package:fullxpet/core/network/http_client.dart';
import 'package:fullxpet/core/services/nav_service.dart';
import 'package:fullxpet/core/storage/token_manager.dart';
import 'package:fullxpet/features/device/repositories/device_repository.dart';
import 'package:fullxpet/locator.dart';
import 'package:fullxpet/routes/app_router.dart';

class UserProvider extends BaseProvider {
  UserDto _user = const UserDto();
  UserDto get user => _user;

  final HttpClient _httpClient = locator<HttpClient>();

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
      final result = await _httpClient.get<Map<String, dynamic>>(ApiEndpoints.userInfo);
      if (result.data != null && (result.code == 0 || result.code == 200)) {
        _user = UserDto.fromJson(result.data!);
        notifyListeners();
      } else if (result.code == 401 || (result.code != null && result.code.toString().startsWith('401'))) {
        await logout();
      } else if (!isSilent) {
        setError(result.message);
      }
    } catch (e) {
      if (!isSilent) {
        setError("获取用户信息失败: $e");
      }
    } finally {
      if (isLoading) setLoading(false);
    }
  }

  // 全局退出登录并清理状态
  Future<void> logout() async {
    try {
      await _httpClient.post<Map<String, dynamic>>(ApiEndpoints.logout);
    } catch (_) {
    } finally {
      locator<DeviceRepository>().clearPool();
      await TokenManager.clearToken();
      _user = const UserDto();
      NavService.go(AppRoutes.login);
    }
  }
}
