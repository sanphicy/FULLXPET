import 'package:flutter/material.dart';
import 'package:fullxpet/common/config/app_config.dart';
import 'package:fullxpet/core/utils/token_manager.dart';
import 'package:fullxpet/core/network/http_client.dart';
import 'package:fullxpet/locator.dart';
import 'package:fullxpet/routes/app_router.dart';
import 'package:fullxpet/app.dart';
import 'package:timezone/data/latest.dart' as tz_data;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();
  setupLocator();

  final config = AppConfig.prod();
  TokenManager.init(accessKey: config.accessTokenKey);
  locator<HttpClient>().init(baseUrl: config.baseUrl);

  AppRouter.setup(AppRoutes.splash);

  runApp(const MyApp());
}
