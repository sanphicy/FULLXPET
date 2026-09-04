import 'package:flutter/foundation.dart';
import 'package:fullxpet/core/network/api_endpoints.dart';
import 'package:fullxpet/core/network/http_client.dart';
import 'package:fullxpet/common/providers/user_provider.dart';
import 'package:fullxpet/locator.dart';

class DeviceAddRepository {
  final HttpClient _httpClient = locator<HttpClient>();

  Future<String?> getDeviceMqttRui() async {
    String countryCode = locator<UserProvider>().user.countryCode;
    try {
      final payload = {"countryCode": countryCode, "clientAppId": "fullxpet"};

      final response = await _httpClient.get<Map<String, dynamic>>(ApiEndpoints.mqttUri, query: payload);
      if (response.code == 0 || response.code == 200) {
        final data = response.data;
        if (data != null && data['deviceMqttEndpoint'] != null && data['deviceMqttPort'] != null) {
          final endpoint = data['deviceMqttEndpoint'];
          final port = data['deviceMqttPort'];
          return "mqtts://$endpoint:$port";
        }
      }
      debugPrint("获取设备MQTT配置失败: ${response.message}");
      return null;
    } catch (e) {
      debugPrint("获取设备MQTT配置异常: $e");
      return null;
    }
  }
}
