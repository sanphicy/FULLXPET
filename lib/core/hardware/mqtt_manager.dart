import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// MQTT 连接凭证模型
class MqttCredentials {
  final String endpoint;
  final int port;
  final String username;
  final String password;
  final String clientId;
  final String subscribeTopic;
  final bool useTls;
  final DateTime? expiresAt;
  final Duration? expiresIn;

  const MqttCredentials({
    required this.endpoint,
    required this.port,
    required this.username,
    required this.password,
    required this.clientId,
    required this.subscribeTopic,
    required this.useTls,
    this.expiresAt,
    this.expiresIn,
  });

  bool get isValid =>
      endpoint.isNotEmpty &&
      port > 0 &&
      username.isNotEmpty &&
      password.isNotEmpty &&
      clientId.isNotEmpty &&
      subscribeTopic.isNotEmpty;

  /// 提前刷新窗口：正常 23h 凭证提前 15 分钟；若为短有效期则按总时长 20% 提前
  Duration get effectiveRefreshLeadTime {
    const maxLead = Duration(minutes: 15);
    if (expiresIn == null || expiresIn! <= Duration.zero) {
      return maxLead;
    }
    final proportional = Duration(milliseconds: (expiresIn!.inMilliseconds * 0.2).round());
    return proportional < maxLead ? proportional : maxLead;
  }

  /// 当前凭证是否已过期或进入提前刷新窗口
  bool needsRefresh() {
    if (expiresAt == null) return false;
    return !DateTime.now().add(effectiveRefreshLeadTime).isBefore(expiresAt!);
  }
}

typedef MqttCredentialFetcher = Future<MqttCredentials?> Function();
typedef MqttConnectedCallback = Future<void> Function();

class MqttManager with WidgetsBindingObserver {
  MqttServerClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _updatesSub;

  MqttCredentials? _currentCreds;
  MqttCredentialFetcher? _credentialFetcher;
  MqttConnectedCallback? _onConnectedCallback;

  bool _shouldMaintainConnection = false;
  bool _observerRegistered = false;
  bool _forceRefreshNextConnect = false;
  int _sessionEpoch = 0;
  int _consecutiveFailures = 0;

  Future<bool>? _inFlightConnect;
  Timer? _refreshTimer;
  Timer? _reconnectTimer;

  // 广播流：所有的 Provider / Repository 都可以同时监听这个流来获取实时数据
  final StreamController _messageController = StreamController.broadcast();
  Stream get messageStream => _messageController.stream;

  bool get isConnected => _client?.connectionStatus?.state == MqttConnectionState.connected;

  String get currentClientId => _currentCreds?.clientId ?? '';

  /// 确保 MQTT 已建立有效连接；若凭证即将过期或指定 [forceRefresh]，将自动刷新凭证并平滑重连
  Future<bool> ensureConnected({
    required MqttCredentialFetcher credentialFetcher,
    MqttConnectedCallback? onConnected,
    bool forceRefresh = false,
  }) async {
    _credentialFetcher = credentialFetcher;
    _onConnectedCallback = onConnected;
    _shouldMaintainConnection = true;
    _ensureObserverRegistered();

    if (!forceRefresh && isConnected && _currentCreds != null && !_currentCreds!.needsRefresh()) {
      return true;
    }

    while (_inFlightConnect != null) {
      if (!forceRefresh) {
        return _inFlightConnect!;
      }
      try {
        await _inFlightConnect;
      } catch (_) {}
      if (!_shouldMaintainConnection) return false;
    }

    final future = _connectInternal(forceRefresh: forceRefresh);
    _inFlightConnect = future;
    try {
      return await future;
    } finally {
      if (identical(_inFlightConnect, future)) {
        _inFlightConnect = null;
      }
    }
  }

  /// 主动断开连接并停止所有自动刷新与退避重连（如退出登录）
  void disconnect() {
    debugPrint('🔌 [MQTT] 主动断开连接');
    _shouldMaintainConnection = false;
    _sessionEpoch++;
    _consecutiveFailures = 0;
    _forceRefreshNextConnect = false;
    _currentCreds = null;
    _cancelTimers();
    _teardownClient();
    _removeObserverIfNeeded();
  }

  Future<bool> _connectInternal({required bool forceRefresh}) async {
    final int epoch = ++_sessionEpoch;
    _cancelTimers();

    final bool needFetch =
        forceRefresh ||
        _forceRefreshNextConnect ||
        _currentCreds == null ||
        !_currentCreds!.isValid ||
        _currentCreds!.needsRefresh();

    if (needFetch) {
      final fetcher = _credentialFetcher;
      if (fetcher == null) return false;

      MqttCredentials? fetched;
      try {
        fetched = await fetcher();
      } catch (e) {
        debugPrint('❌ [MQTT] 拉取凭证异常: $e');
      }

      if (!_shouldMaintainConnection || epoch != _sessionEpoch) return false;

      if (fetched == null || !fetched.isValid) {
        debugPrint('❌ [MQTT] 凭证无效，等待退避重试');
        _consecutiveFailures++;
        _forceRefreshNextConnect = true;
        _scheduleReconnect(epoch);
        return false;
      }

      _currentCreds = fetched;
      _forceRefreshNextConnect = false;
    }

    final creds = _currentCreds;
    if (creds == null || !creds.isValid) return false;

    // 建立新连接前先无副作用释放旧连接（支持在线状态下平滑轮换新凭证）
    _teardownClient();
    if (!_shouldMaintainConnection || epoch != _sessionEpoch) return false;

    final client = MqttServerClient.withPort(creds.endpoint, creds.clientId, creds.port);
    client.logging(on: false);
    client.keepAlivePeriod = 30;
    client.secure = creds.useTls;
    // 关闭 SDK 内置自动重连，改由本类统一控制退避与凭证过期刷新
    client.autoReconnect = false;

    bool sessionEstablished = false;
    client.onConnected = () {
      if (epoch != _sessionEpoch) return;
      debugPrint('✅ [MQTT 回调] 成功连上服务器 (clientId: ${creds.clientId})');
    };
    client.onDisconnected = () {
      if (epoch != _sessionEpoch || !sessionEstablished) return;
      _handleUnexpectedDisconnect(epoch);
    };

    try {
      debugPrint('🌐 [MQTT] 正在连接 ${creds.endpoint}:${creds.port} (clientId: ${creds.clientId})...');
      await client.connect(creds.username, creds.password);
    } on NoConnectionException catch (e) {
      debugPrint('❌ [MQTT] 连接异常: $e, returnCode=${client.connectionStatus?.returnCode}');
      _handleConnectFailure(client, epoch);
      return false;
    } catch (e) {
      debugPrint('❌ [MQTT] 未知异常: $e, returnCode=${client.connectionStatus?.returnCode}');
      _handleConnectFailure(client, epoch);
      return false;
    }

    if (!_shouldMaintainConnection || epoch != _sessionEpoch) {
      _disposeClientQuietly(client);
      return false;
    }

    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      debugPrint(
        '❌ [MQTT] 连接失败，state=${client.connectionStatus?.state}, returnCode=${client.connectionStatus?.returnCode}',
      );
      _handleConnectFailure(client, epoch);
      return false;
    }

    _client = client;
    sessionEstablished = true;
    _consecutiveFailures = 0;

    client.subscribe(creds.subscribeTopic, MqttQos.atLeastOnce);
    debugPrint('📡 [MQTT] 已订阅主题: ${creds.subscribeTopic}');

    _updatesSub = client.updates?.listen(
      (List<MqttReceivedMessage<MqttMessage>> messages) {
        for (final msg in messages) {
          final payloadMsg = msg.payload;
          if (payloadMsg is! MqttPublishMessage) continue;
          final String payload = MqttPublishPayload.bytesToStringAsString(payloadMsg.payload.message);
          try {
            final decoded = jsonDecode(payload);
            if (decoded is Map<String, dynamic>) {
              _messageController.add(decoded);
            } else if (decoded is Map) {
              _messageController.add(Map<String, dynamic>.from(decoded));
            }
          } catch (e) {
            debugPrint('⚠️ [MQTT 消息解析失败] $payload');
          }
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('⚠️ [MQTT 消息流异常] $error');
      },
    );

    _scheduleCredentialRefresh(creds, epoch);

    final callback = _onConnectedCallback;
    if (callback != null) {
      try {
        await callback();
      } catch (e) {
        debugPrint('⚠️ [MQTT] 连上后同步订阅回调异常: $e');
      }
    }

    return _shouldMaintainConnection && epoch == _sessionEpoch && isConnected;
  }

  void _handleConnectFailure(MqttServerClient failedClient, int epoch) {
    final returnCode = failedClient.connectionStatus?.returnCode;
    _disposeClientQuietly(failedClient);

    if (!_shouldMaintainConnection || epoch != _sessionEpoch) return;

    _consecutiveFailures++;
    final bool isAuthRejected =
        returnCode == MqttConnectReturnCode.badUsernameOrPassword ||
        returnCode == MqttConnectReturnCode.notAuthorized ||
        returnCode == MqttConnectReturnCode.identifierRejected;

    // 明确鉴权拒连，或连续失败达到 2 次（兼容 AWS IoT 自定义鉴权直接断流不返回明确 code 的情况），强制重拉凭证
    if (isAuthRejected || _consecutiveFailures >= 2) {
      _forceRefreshNextConnect = true;
    }
    _scheduleReconnect(epoch);
  }

  void _handleUnexpectedDisconnect(int epoch) {
    debugPrint('⚠️ [MQTT 回调] 连接意外断开');
    _cancelTimers();
    _teardownClient(callDisconnect: false);
    if (!_shouldMaintainConnection || epoch != _sessionEpoch) return;
    _scheduleReconnect(epoch);
  }

  void _scheduleCredentialRefresh(MqttCredentials creds, int epoch) {
    _refreshTimer?.cancel();
    if (creds.expiresAt == null) return;

    Duration delay = creds.expiresAt!.difference(DateTime.now()) - creds.effectiveRefreshLeadTime;
    // 防御极端时间异常导致的 0ms 紧循环刷新
    if (delay < const Duration(seconds: 5)) {
      delay = const Duration(seconds: 5);
    }

    debugPrint('⏰ [MQTT] 已安排凭证自动刷新，距今 ${delay.inMinutes} 分钟 (${delay.inSeconds}s)');
    _refreshTimer = Timer(delay, () {
      if (!_shouldMaintainConnection || epoch != _sessionEpoch) return;
      final fetcher = _credentialFetcher;
      if (fetcher == null) return;
      debugPrint('🔄 [MQTT] 凭证临近过期，主动刷新并平滑重连...');
      unawaited(ensureConnected(credentialFetcher: fetcher, onConnected: _onConnectedCallback, forceRefresh: true));
    });
  }

  void _scheduleReconnect(int epoch) {
    _reconnectTimer?.cancel();
    if (!_shouldMaintainConnection || epoch != _sessionEpoch) return;

    // 指数退避：2s -> 4s -> 8s -> 16s -> 30s 封顶
    final int exponent = math.min(_consecutiveFailures, 4);
    final int delaySec = math.min(30, 2 * (1 << exponent));
    debugPrint('🔄 [MQTT] 将在 ${delaySec}s 后重连 (连续失败: $_consecutiveFailures, 强制换凭证: $_forceRefreshNextConnect)');

    _reconnectTimer = Timer(Duration(seconds: delaySec), () {
      if (!_shouldMaintainConnection || epoch != _sessionEpoch) return;
      final fetcher = _credentialFetcher;
      if (fetcher == null) return;
      unawaited(
        ensureConnected(
          credentialFetcher: fetcher,
          onConnected: _onConnectedCallback,
          forceRefresh: _forceRefreshNextConnect,
        ),
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!_shouldMaintainConnection || _credentialFetcher == null) return;

    final bool credsNeedRefresh = _currentCreds == null || _currentCreds!.needsRefresh();
    if (!isConnected || credsNeedRefresh) {
      debugPrint('📱 [MQTT] 回到前台自检: isConnected=$isConnected, credsNeedRefresh=$credsNeedRefresh，触发恢复连接');
      _consecutiveFailures = 0;
      unawaited(
        ensureConnected(
          credentialFetcher: _credentialFetcher!,
          onConnected: _onConnectedCallback,
          forceRefresh: credsNeedRefresh,
        ),
      );
    }
  }

  void _teardownClient({bool callDisconnect = true}) {
    _updatesSub?.cancel();
    _updatesSub = null;
    final oldClient = _client;
    _client = null;
    if (oldClient != null) {
      _disposeClientQuietly(oldClient, callDisconnect: callDisconnect);
    }
  }

  void _disposeClientQuietly(MqttServerClient client, {bool callDisconnect = true}) {
    client.onConnected = null;
    client.onDisconnected = null;
    if (!callDisconnect) return;
    try {
      client.disconnect();
    } catch (_) {}
  }

  void _cancelTimers() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _ensureObserverRegistered() {
    if (_observerRegistered) return;
    WidgetsBinding.instance.addObserver(this);
    _observerRegistered = true;
  }

  void _removeObserverIfNeeded() {
    if (!_observerRegistered) return;
    WidgetsBinding.instance.removeObserver(this);
    _observerRegistered = false;
  }
}
