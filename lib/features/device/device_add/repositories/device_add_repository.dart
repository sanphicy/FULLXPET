import 'package:flutter/foundation.dart';
import 'package:fullxpet/core/network/api_endpoints.dart';
import 'package:fullxpet/core/network/http_client.dart';
import 'package:fullxpet/locator.dart';

class DeviceAddRepository {
  final HttpClient _httpClient = locator<HttpClient>();

  Future<String?> getDeviceMqttRui() async {
    try {
      final payload = {"countryCode": "US", "clientAppId": "stellapets"};

      final response = await _httpClient.get<Map<String, dynamic>>(ApiEndpoints.mqttUri, query: payload);
      print(response.data.toString());
      if (response.code == 0 || response.code == 200) {
        final data = response.data;
        if (data != null && data['deviceMqttEndpoint'] != null && data['deviceMqttPort'] != null) {
          final endpoint = data['deviceMqttEndpoint'];
          final port = data['deviceMqttPort'];
          // 拼接路径和端口号
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
