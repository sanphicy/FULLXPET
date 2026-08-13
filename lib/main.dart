import 'package:flutter/material.dart';
import 'package:fullxpet/common/config/app_config.dart';
import 'package:fullxpet/core/utils/token_manager.dart';
import 'package:fullxpet/core/network/http_client.dart';
import 'package:fullxpet/locator.dart';
import 'package:fullxpet/routes/app_router.dart';
import 'package:fullxpet/app.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:fullxpet/core/network/api_endpoints.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();
  setupLocator();

  final config = AppConfig.prod();
  TokenManager.init(accessKey: config.accessTokenKey);
  locator<HttpClient>().init(baseUrl: config.baseUrl);

  // 临时添加 start：启动时获取动态 baseUrl
  try {
    final HttpClient httpClient = locator<HttpClient>();
    final payload = {"countryCode": "CN", "clientAppId": "fullxpet"};

    // 2. 发起请求
    final response = await httpClient.get<Map<String, dynamic>>(ApiEndpoints.mqttUri, query: payload);

    if (response.code == 0 || response.code == 200) {
      final data = response.data;
      if (data != null && data['apiBaseUrl'] != null) {
        String apiBaseUrl = data['apiBaseUrl'].toString();
        if (apiBaseUrl.endsWith('/app')) {
          apiBaseUrl = apiBaseUrl.substring(0, apiBaseUrl.length - 4);
        }
        // 3. 动态更新 baseUrl
        locator<HttpClient>().init(baseUrl: apiBaseUrl);
      }
    }
  } catch (e) {}
  // 临时添加 end

  AppRouter.setup(AppRoutes.splash);

  runApp(const MyApp());
}
