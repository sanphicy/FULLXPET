import 'package:flutter/material.dart';
import 'package:fullxpet/common/config/app_config.dart';
import 'package:fullxpet/core/network/http_client.dart';
import 'package:fullxpet/core/utils/device_batch_helper.dart';
import 'package:fullxpet/core/storage/token_manager.dart';
import 'package:fullxpet/locator.dart';
import 'package:fullxpet/routes/app_router.dart';
import 'package:fullxpet/app.dart';
import 'package:timezone/data/latest.dart' as tz_data;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化时区数据
  tz_data.initializeTimeZones();

  // 注册 GetIt 依赖注入容器
  setupLocator();

  // 本地基础配置与 Token 初始化
  final config = AppConfig.prod();
  TokenManager.init(accessKey: config.accessTokenKey);
  locator<HttpClient>().init(baseUrl: config.baseUrl);

  // 设备批次映射辅助初始化
  await DeviceBatchHelper().init();

  // 初始化路由并默认进入 Splash 闪屏页
  AppRouter.setup(AppRoutes.splash);

  // 挂载 UI 树
  runApp(const MyApp());
}
