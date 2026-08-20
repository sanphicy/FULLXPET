import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttManager {
  MqttServerClient? _client;

  // 广播流：所有的 Provider 都可以同时监听这个流来获取实时数据
  final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  bool get isConnected => _client?.connectionStatus?.state == MqttConnectionState.connected;

  Future<bool> connect({
    required String endpoint,
    required int port,
    required String username,
    required String password,
    required String clientId,
    required String subscribeTopic,
    required bool useTls,
  }) async {
    if (isConnected) return true;

    // 初始化客户端
    _client = MqttServerClient.withPort(endpoint, clientId, port);
    _client!.logging(on: false);
    _client!.keepAlivePeriod = 30; // 30秒心跳包
    _client!.secure = useTls; // 是否使用 TLS 加密

    // 自动重连机制
    _client!.autoReconnect = true;
    _client!.onDisconnected = _onDisconnected;
    _client!.onConnected = _onConnected;
    _client!.onAutoReconnect = _onAutoReconnect;

    // 建立连接
    try {
      debugPrint('🌐 [MQTT] 正在连接服务器: $endpoint:$port...');
      await _client!.connect(username, password);
    } on NoConnectionException catch (e) {
      debugPrint('❌ [MQTT] 连接异常: $e');
      disconnect();
      return false;
    } catch (e) {
      debugPrint('❌ [MQTT] 未知异常: $e');
      disconnect();
      return false;
    }

    // 验证并订阅 Topic
    if (isConnected) {
      debugPrint('✅ [MQTT] 连接成功！');
      _client!.subscribe(subscribeTopic, MqttQos.atLeastOnce);
      debugPrint('📡 [MQTT] 已订阅主题: $subscribeTopic');

      // 开启监听数据通道
      _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final String payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

        try {
          // MQTT信息监听并塞进广播流
          final Map<String, dynamic> data = jsonDecode(payload);
          _messageController.add(data);
        } catch (e) {
          debugPrint('⚠️ [MQTT 消息解析失败] $payload');
        }
      });
      return true;
    } else {
      debugPrint('❌ [MQTT] 连接失败，状态: ${_client!.connectionStatus?.state}');
      disconnect();
      return false;
    }
  }

  void disconnect() {
    debugPrint('🔌 [MQTT] 主动断开连接');
    _client?.disconnect();
    _client = null;
  }

  // --- 生命周期回调 ---
  void _onConnected() => debugPrint('✅ [MQTT 回调] 成功连上服务器');
  void _onDisconnected() => debugPrint('⚠️ [MQTT 回调] 连接已断开');
  void _onAutoReconnect() => debugPrint('🔄 [MQTT 回调] 正在自动重连...');
}
