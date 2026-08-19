import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/core/services/region_service.dart';
import 'package:fullxpet/core/utils/token_manager.dart';
import 'package:fullxpet/locator.dart';

enum BootstrapResult { authenticated, unauthenticated, error }

class SplashViewModel extends BaseProvider {
  final RegionService _regionService = locator<RegionService>();

  Future<BootstrapResult> bootstrapApp() async {
    final startTime = DateTime.now();

    try {
      // 1. 检查登录态
      final bool loggedIn = await TokenManager.isLoggedIn();

      // 2. 初始化数据中心与区域引导
      await _regionService.initBootstrap(isLoggedIn: loggedIn);

      // 3. 保证 Logo 至少展示 1 秒防跳闪
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      if (elapsed < 1000) {
        await Future.delayed(Duration(milliseconds: 1000 - elapsed));
      }

      return loggedIn
          ? BootstrapResult.authenticated
          : BootstrapResult.unauthenticated;
    } catch (e) {
      setError(e.toString());
      return BootstrapResult.error;
    }
  }
}
