import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fullxpet/core/hardware/mqtt_manager.dart';
import 'package:fullxpet/core/network/api_client.dart';
import 'package:fullxpet/core/network/api_endpoints.dart';
import 'package:fullxpet/core/utils/uuids_tool.dart';
import 'package:fullxpet/features/device/models/device_hardware_info.dart';
import 'package:fullxpet/features/device/models/device_item_dto.dart';
import 'package:fullxpet/features/device/models/device_properties_dto.dart';
import 'package:fullxpet/features/device/models/mqtt_attr_report_dto.dart';
import 'package:fullxpet/features/device/models/product_dto.dart';
import 'package:fullxpet/features/device/models/feeder_live_info.dart';
import 'package:fullxpet/locator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fullxpet/features/device/models/device_log.dart';

typedef JsonMap = Map<String, dynamic>;
typedef ProductCacheMap = Map<String, ProductDto>;
typedef DeviceBasicCacheMap = Map<String, DeviceItemDto>;
typedef DpidValueMap = Map<String, dynamic>;
typedef DeviceDpidCacheMap = Map<String, DpidValueMap>;
typedef DeviceHardwareCacheMap = Map<String, DeviceHardwareInfo>;

typedef ProductDtoList = List<ProductDto>;
typedef DeviceItemDtoList = List<DeviceItemDto>;
typedef CommandAttrList = List<JsonMap>;

class DeviceRepository {
  final Dio _dio = locator<ApiClient>().dio;
  final MqttManager _mqttManager = locator<MqttManager>();

  /// 底表 1：产品列表缓存表 (key = productId)
  final ProductCacheMap _productCache = {};

  /// 底表 2：设备列表基础信息缓存表 (key = deviceId)
  final DeviceBasicCacheMap _deviceBasicCache = {};

  /// 底表 3：单台设备 DPID 属性状态底表 (key = deviceId, value = {dpid: 清洗后的真实值})
  final DeviceDpidCacheMap _deviceDpidCache = {};

  /// 附加底表：单台设备硬件与网络信息表 (key = deviceId, 存 ssid/rssi/mcuVersion/imei 等)
  final DeviceHardwareCacheMap _deviceHardwareCache = {};

  /// 设备数据变更广播流（发送变更的 deviceId；若列表整体刷新则发送 'ALL'）
  final StreamController<String> _deviceUpdateController = StreamController<String>.broadcast();
  Stream<String> get onDeviceUpdated => _deviceUpdateController.stream;
  final StreamController<({String deviceId, Set<String> dpids})> _dpidUpdateController =
      StreamController<({String deviceId, Set<String> dpids})>.broadcast();
  final StreamController<MqttAttrReportDto> _mqttAttrReportController = StreamController<MqttAttrReportDto>.broadcast();
  Stream<MqttAttrReportDto> get onMqttAttrReport => _mqttAttrReportController.stream;
  Stream<({String deviceId, Set<String> dpids})> get onDpidUpdated => _dpidUpdateController.stream;
  StreamSubscription? _mqttSub;
  final Set<String> _syncedDeviceIds = {};
  final Map<String, Future<DevicePropertiesDto?>> _inFlightPropertyRequests = {};
  int _poolEpoch = 0;
  int _mqttConnectedSyncSeq = 0;
  static const String _kClientInstanceIdKey = 'client_instance_id';
  Future<String>? _clientInstanceIdFuture;
  String? _cachedClientInstanceId;
  static final RegExp _clientInstanceIdRegex = RegExp(
    r'^([0-9a-fA-F]{32}|[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})$',
  );

  DeviceRepository() {
    _startListeningMqtt();
  }

  // ------------------- 同步读取底表方法 -------------------

  /// 【底表 1】获取所有缓存的产品列表
  ProductDtoList get cachedProducts => _productCache.values.toList();

  /// 【底表 1】根据完整 productId 获取产品 DTO
  ProductDto? getProduct(String productId) {
    if (productId.isEmpty) return null;
    final cleanId = productId.trim().toLowerCase();
    for (final p in _productCache.values) {
      if (p.productId.trim().toLowerCase() == cleanId) return p;
    }
    return null;
  }

  /// 【底表 1】根据蓝牙广播 2 字节短码 (productShortId) 查找产品 DTO
  ProductDto? findProductByShortId(String shortId) {
    if (shortId.isEmpty) return null;
    final cleanShort = shortId.trim().toLowerCase().replaceAll('0x', '');
    final String reversedShort = (cleanShort.length == 4)
        ? '${cleanShort.substring(2, 4)}${cleanShort.substring(0, 2)}'
        : cleanShort;

    for (final p in _productCache.values) {
      final apiShort = p.productShortId.trim().toLowerCase().replaceAll('0x', '');
      final apiFull = p.productId.trim().toLowerCase();
      if (apiShort.isNotEmpty && (apiShort == cleanShort || apiShort == reversedShort)) {
        return p;
      }
      if (apiFull.isNotEmpty && (apiFull.startsWith(cleanShort) || apiFull.startsWith(reversedShort))) {
        return p;
      }
    }
    return null;
  }

  /// 【底表 2】获取缓存的设备列表（按 sortOrder 排序）
  DeviceItemDtoList get cachedDeviceList =>
      _deviceBasicCache.values.toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  /// 【底表 2】根据 deviceId 获取单台设备基础信息 DTO
  DeviceItemDto? getDeviceBasic(String deviceId) => _deviceBasicCache[deviceId];

  /// 【底表 3】根据 deviceId 获取单台设备的全部 DPID 键值字典
  DpidValueMap getDeviceDpidMap(String deviceId) => _deviceDpidCache[deviceId] ?? const {};

  /// 【底表 3 单项】根据 deviceId 和 dpid 直接读取某个属性的值
  dynamic getDpidValue(String deviceId, String dpid) => _deviceDpidCache[deviceId]?[dpid];

  /// 【硬件表】根据 deviceId 获取单台设备的硬件与网络信息 (ssid/rssi/mcuVersion)
  DeviceHardwareInfo getDeviceHardwareInfo(String deviceId) =>
      _deviceHardwareCache[deviceId] ?? const DeviceHardwareInfo();

  // ------------------- HTTP 请求并自动写表方法 -------------------

  /// 拉取产品列表 -> 自动存入 _productCache
  Future<ProductDtoList> fetchProducts({bool forceRefresh = false}) async {
    if (_productCache.isNotEmpty && !forceRefresh) {
      return cachedProducts;
    }
    final res = await _dio.get(ApiEndpoints.products);
    final data = res.data;
    if (data is Map) {
      final items = data['items'];
      if (items is List) {
        _productCache.clear();
        for (final raw in items) {
          if (raw is Map) {
            final dto = ProductDto.fromJson(JsonMap.from(raw));
            if (dto.productId.isNotEmpty) {
              _productCache[dto.productId] = dto;
            }
          }
        }
      }
    }
    return cachedProducts;
  }

  /// 拉取设备列表 -> 自动存入 _deviceBasicCache
  Future<DeviceItemDtoList> getDeviceList() async {
    if (_productCache.isEmpty) {
      try {
        await fetchProducts();
      } catch (e) {
        debugPrint('预拉取产品列表失败: $e');
      }
    }
    final res = await _dio.get(ApiEndpoints.devices);
    final data = res.data;
    if (data is Map) {
      final items = data['items'];
      if (items is List) {
        _deviceBasicCache.clear();
        for (final raw in items) {
          if (raw is Map) {
            final dto = DeviceItemDto.fromJson(JsonMap.from(raw));
            if (dto.deviceId.isNotEmpty) {
              _deviceBasicCache[dto.deviceId] = dto;
            }
          }
        }
      }
    }
    _notify('ALL');
    return cachedDeviceList;
  }

  Future<DeviceItemDto?> ensureDeviceBasicLoaded(String deviceId) async {
    final cached = getDeviceBasic(deviceId);
    if (cached != null) return cached;
    await getDeviceList();
    return getDeviceBasic(deviceId);
  }

  /// 拉取单台设备全量属性 -> 自动存入 _deviceDpidCache 与 _deviceHardwareCache
  Future<DevicePropertiesDto?> fetchDeviceProperties(String deviceId) {
    final existing = _inFlightPropertyRequests[deviceId];
    if (existing != null) return existing;

    final int epoch = _poolEpoch;
    late final Future<DevicePropertiesDto?> future;
    future = _fetchDevicePropertiesInternal(deviceId, epoch).whenComplete(() {
      if (identical(_inFlightPropertyRequests[deviceId], future)) {
        _inFlightPropertyRequests.remove(deviceId);
      }
    });
    _inFlightPropertyRequests[deviceId] = future;
    return future;
  }

  Future<DevicePropertiesDto?> _fetchDevicePropertiesInternal(String deviceId, int epoch) async {
    try {
      final res = await _dio.get(ApiEndpoints.deviceProperties(deviceId));
      if (epoch != _poolEpoch) return null;
      final data = res.data;
      if (data is Map) {
        final dto = DevicePropertiesDto.fromJson(data);

        final existingBasic = _deviceBasicCache[deviceId];
        if (existingBasic != null && existingBasic.online != dto.online) {
          _deviceBasicCache[deviceId] = existingBasic.copyWith(online: dto.online);
        }

        _deviceHardwareCache[deviceId] = dto.deviceInfo;
        final dpidMap = dto.toDpidMap();
        _deviceDpidCache[deviceId] = dpidMap;
        _dpidUpdateController.add((deviceId: deviceId, dpids: dpidMap.keys.toSet()));
        _notify(deviceId);
        return dto;
      }
    } catch (e) {
      debugPrint('拉取设备属性失败 [$deviceId]:$e');
    }
    return null;
  }

  /// 下发 DPID 控制指令
  Future<bool> sendDeviceCommand(String deviceId, CommandAttrList attributes) async {
    try {
      await _dio.post(ApiEndpoints.deviceInvoke(deviceId), data: {'attributes': attributes});
      return true;
    } catch (e) {
      debugPrint('发送指令失败 [$deviceId]:$e');
      return false;
    }
  }

  /// 修改设备名称 -> 成功后直接更新底表 2 并广播
  Future<bool> renameDevice(String deviceId, String newName) async {
    try {
      await _dio.patch(ApiEndpoints.deviceName(deviceId), data: {'nickname': newName});
      final existing = _deviceBasicCache[deviceId];
      if (existing != null) {
        _deviceBasicCache[deviceId] = existing.copyWith(nickname: newName);
      }
      _notify(deviceId);
      return true;
    } catch (e) {
      debugPrint('重命名失败 [$deviceId]:$e');
      return false;
    }
  }

  /// 解绑并删除设备 -> 直接从底表 2 拿 homeId，删除成功后清理所有底表
  Future<bool> deleteDevice(String deviceId) async {
    try {
      String homeId = _deviceBasicCache[deviceId]?.homeId ?? '';
      if (homeId.isEmpty) {
        final homeList = await _dio.get(ApiEndpoints.homeList);
        final listData = homeList.data;
        if (listData is Map && listData['items'] is List && (listData['items'] as List).isNotEmpty) {
          homeId = listData['items'][0]['id']?.toString() ?? '';
        }
      }
      if (homeId.isEmpty) return false;

      await _dio.delete(ApiEndpoints.deviceUnBind(homeId, deviceId));
      _deviceBasicCache.remove(deviceId);
      _deviceDpidCache.remove(deviceId);
      _deviceHardwareCache.remove(deviceId);
      _syncedDeviceIds.remove(deviceId);
      _notify('ALL');
      return true;
    } catch (e) {
      debugPrint('删除设备失败 [$deviceId]:$e');
    }
    return false;
  }

  /// 通用日志拉取
  Future<JsonMap> fetchDeviceLogsRaw(
    String deviceId, {
    required String dpidFilter,
    required String fromIsoUtc,
    required String toIsoUtc,
    int pageSize = 20,
    String sort = 'desc',
    String? pageToken,
  }) async {
    final JsonMap query = {
      'from': fromIsoUtc,
      'to': toIsoUtc,
      'dpid': dpidFilter,
      'pageSize': pageSize.toString(),
      'sort': sort,
    };
    if (pageToken != null && pageToken.isNotEmpty) {
      query['pageToken'] = pageToken;
    }
    final res = await _dio.get(ApiEndpoints.deviceLogs(deviceId), queryParameters: query);
    if (res.data is Map) {
      return JsonMap.from(res.data as Map);
    }
    return {};
  }

  /// 分页拉取设备属性日志（强类型返回 items / nextPageToken / hasMore）
  Future<DeviceLogPageDto> fetchDeviceLogsPage(
    String deviceId, {
    required String dpidFilter,
    required String fromIsoUtc,
    required String toIsoUtc,
    int pageSize = 20,
    String sort = 'desc',
    String? pageToken,
  }) async {
    final raw = await fetchDeviceLogsRaw(
      deviceId,
      dpidFilter: dpidFilter,
      fromIsoUtc: fromIsoUtc,
      toIsoUtc: toIsoUtc,
      pageSize: pageSize,
      sort: sort,
      pageToken: pageToken,
    );
    return DeviceLogPageDto.fromJson(raw);
  }

  /// 检查设备是否有待升级固件
  Future<JsonMap?> checkPendingFirmware(String deviceId) async {
    try {
      final res = await _dio.get(ApiEndpoints.checkFirmware(deviceId));
      final rawData = res.data;
      if (rawData is List && rawData.isNotEmpty) {
        return JsonMap.from(rawData.first as Map);
      } else if (rawData is Map) {
        return JsonMap.from(rawData);
      }
    } catch (_) {}
    return null;
  }

  /// 下发固件升级指令
  Future<bool> dispatchFirmwareUpgrade(String deviceId, String recordId) async {
    try {
      await _dio.post(ApiEndpoints.upgradeFirmware(deviceId, recordId));
      return true;
    } catch (e) {
      debugPrint('下发固件升级指令失败 [$deviceId]:$e');
      return false;
    }
  }

  /// 获取设备视频直播参数
  Future<FeederLiveInfo> fetchLiveInfo(String deviceId, {int camera = 0, int resolution = 0}) async {
    final String platform = Platform.isIOS ? 'ios' : 'android';
    final String clientInstanceId = await getClientInstanceId();
    final JsonMap payload = {
      'clientInstanceId': clientInstanceId,
      'platform': platform,
      'camera': camera,
      'resolution': resolution,
    };
    final res = await _dio.post(ApiEndpoints.deviceLiveVideo(deviceId), data: payload);
    return FeederLiveInfo.fromJson(JsonMap.from(res.data as Map));
  }

  /// 获取 MQTT 凭证
  Future<JsonMap> fetchMqttCredentials() async {
    final res = await _dio.post(ApiEndpoints.mqttCredentials);
    if (res.data is Map) {
      return JsonMap.from(res.data as Map);
    }
    return {};
  }

  /// 一键同步 MQTT 订阅
  Future<bool> syncMqttSubscriptions() async {
    try {
      await _dio.post(ApiEndpoints.mqttSubscribeSync);
      return true;
    } catch (e) {
      debugPrint('一键同步订阅失败: $e');
      return false;
    }
  }

  /// 确保 MQTT 已按当前设备列表建立连接并完成订阅同步（含单机唯一 clientId 后缀与凭证自动刷新）
  Future<bool> ensureMqttReadyForCurrentDevices() async {
    final currentIds = _deviceBasicCache.keys.toSet();
    if (currentIds.isEmpty) return false;

    final int beforeSyncSeq = _mqttConnectedSyncSeq;
    final bool connected = await _mqttManager.ensureConnected(
      credentialFetcher: _fetchMqttCredentialsModel,
      onConnected: _handleMqttConnected,
    );
    if (!connected) return false;

    // 本次建连或凭证刷新重连已触发 _handleMqttConnected，不再重复同步
    if (_mqttConnectedSyncSeq != beforeSyncSeq) return true;

    if (_isSameDeviceSet(_syncedDeviceIds, currentIds)) return true;

    final bool synced = await syncMqttSubscriptions();
    if (synced) {
      _syncedDeviceIds
        ..clear()
        ..addAll(currentIds);
    }
    return synced;
  }

  Future<void> _handleMqttConnected() async {
    _mqttConnectedSyncSeq++;
    final currentIds = _deviceBasicCache.keys.toSet();
    if (currentIds.isEmpty) return;

    final bool synced = await syncMqttSubscriptions();
    if (synced) {
      _syncedDeviceIds
        ..clear()
        ..addAll(currentIds);
    }
  }

  Future<MqttCredentials?> _fetchMqttCredentialsModel() async {
    final credMap = await fetchMqttCredentials();
    final mqttRaw = credMap['mqtt'];
    if (mqttRaw is! Map) return null;

    final mqttData = JsonMap.from(mqttRaw);
    final rawHint = mqttData['clientIdHint']?.toString().trim() ?? '';
    final instanceId = await getClientInstanceId();
    final cleanHex = instanceId.replaceAll(RegExp(r'[^0-9a-fA-F]'), '').toLowerCase();
    final suffix = cleanHex.length >= 8 ? cleanHex.substring(0, 8) : cleanHex;
    final effectiveClientId = (rawHint.isNotEmpty && suffix.isNotEmpty) ? '$rawHint-$suffix' : rawHint;

    // 优先使用相对秒数 expiresInSeconds，避免本机时钟偏差；缺失时回退解析 expiresAt
    final rawExpiresIn = mqttData['expiresInSeconds'] ?? credMap['expiresInSeconds'];
    final int? expiresInSeconds = rawExpiresIn != null ? int.tryParse(rawExpiresIn.toString()) : null;
    final rawExpiresAt = mqttData['expiresAt'] ?? credMap['expiresAt'];

    Duration? expiresIn;
    DateTime? expiresAt;
    if (expiresInSeconds != null && expiresInSeconds > 0) {
      expiresIn = Duration(seconds: expiresInSeconds);
      expiresAt = DateTime.now().add(expiresIn);
    } else if (rawExpiresAt != null && rawExpiresAt.toString().trim().isNotEmpty) {
      final parsed = DateTime.tryParse(rawExpiresAt.toString().trim());
      if (parsed != null) {
        expiresAt = parsed.toLocal();
        final diff = expiresAt.difference(DateTime.now());
        if (diff > Duration.zero) {
          expiresIn = diff;
        }
      }
    }

    debugPrint('🔑 [MQTT 凭证] clientId=$effectiveClientId | expiresIn=${expiresIn?.inSeconds}s | expiresAt=$expiresAt');

    return MqttCredentials(
      endpoint: mqttData['endpoint']?.toString().trim() ?? '',
      port: int.tryParse(mqttData['port']?.toString() ?? '') ?? 8883,
      username: mqttData['username']?.toString() ?? '',
      password: mqttData['password']?.toString() ?? '',
      clientId: effectiveClientId,
      subscribeTopic: mqttData['subscribeTopic']?.toString().trim() ?? '',
      useTls: mqttData['tls'] == true || mqttData['tls']?.toString().toLowerCase() == 'true',
      expiresAt: expiresAt,
      expiresIn: expiresIn,
    );
  }

  bool _isSameDeviceSet(Set<String> a, Set<String> b) => a.length == b.length && a.containsAll(b);

  /// 清空四张底表（退出登录时调用）
  void clearPool() {
    _poolEpoch++;
    _inFlightPropertyRequests.clear();
    _productCache.clear();
    _deviceBasicCache.clear();
    _deviceDpidCache.clear();
    _deviceHardwareCache.clear();
    _syncedDeviceIds.clear();
    _mqttManager.disconnect();
  }

  void _notify(String deviceId) {
    _deviceUpdateController.add(deviceId);
  }

  /// 获取或首次生成单机持久化客户端实例 ID（符合标准 UUID / 32 位 hex 正则）
  Future<String> getClientInstanceId() {
    if (_cachedClientInstanceId != null && _clientInstanceIdRegex.hasMatch(_cachedClientInstanceId!)) {
      return Future.value(_cachedClientInstanceId!);
    }
    return _clientInstanceIdFuture ??= _loadOrCreateClientInstanceId().whenComplete(() {
      _clientInstanceIdFuture = null;
    });
  }

  Future<String> _loadOrCreateClientInstanceId() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kClientInstanceIdKey)?.trim();
    if (saved != null && _clientInstanceIdRegex.hasMatch(saved)) {
      _cachedClientInstanceId = saved;
      return saved;
    }

    String generatedId = UuidsTool.generateStandardUUID();
    if (!_clientInstanceIdRegex.hasMatch(generatedId)) {
      final cleanHex = generatedId.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
      if (cleanHex.length == 32) {
        generatedId = cleanHex;
      }
    }

    if (_clientInstanceIdRegex.hasMatch(generatedId)) {
      await prefs.setString(_kClientInstanceIdKey, generatedId);
      _cachedClientInstanceId = generatedId;
    }
    return generatedId;
  }

  void _startListeningMqtt() {
    _mqttSub = _mqttManager.messageStream.listen((data) {
      debugPrint('[MQTT 原始消息]: $data');
      final type = data['type']?.toString();
      if (type != 'attr_report') return;

      final report = MqttAttrReportDto.fromJson(JsonMap.from(data));
      if (report.deviceId.isNotEmpty && report.effectiveChanges.isNotEmpty) {
        // 收到设备主动上报，说明设备当前在线，修正离线缓存
        final existingBasic = _deviceBasicCache[report.deviceId];
        if (existingBasic != null && !existingBasic.online) {
          _deviceBasicCache[report.deviceId] = existingBasic.copyWith(online: true);
        }

        final dpidMap = _deviceDpidCache.putIfAbsent(report.deviceId, () => {});
        final Set<String> updatedKeys = {};
        report.effectiveChanges.forEach((dpid, value) {
          dpidMap[dpid] = value;
          updatedKeys.add(dpid);
        });

        _dpidUpdateController.add((deviceId: report.deviceId, dpids: updatedKeys));
        _mqttAttrReportController.add(report);
        _notify(report.deviceId);
      }
    });
  }

  void dispose() {
    _mqttSub?.cancel();
    _mqttAttrReportController.close();
    _dpidUpdateController.close();
    _deviceUpdateController.close();
  }
}
