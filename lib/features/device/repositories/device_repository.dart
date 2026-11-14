import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:fullxpet/core/hardware/mqtt_manager.dart';
import 'package:fullxpet/core/network/api_endpoints.dart';
import 'package:fullxpet/core/network/http_client.dart';
import 'package:fullxpet/core/network/result_model.dart';
import 'package:fullxpet/core/utils/uuids_tool.dart';
import 'package:fullxpet/features/device/models/device_hardware_info.dart';
import 'package:fullxpet/features/device/models/device_item_dto.dart';
import 'package:fullxpet/features/device/models/device_properties_dto.dart';
import 'package:fullxpet/features/device/models/mqtt_attr_report_dto.dart';
import 'package:fullxpet/features/device/models/product_dto.dart';
import 'package:fullxpet/features/device/products/feeder/models/feeder_live_info.dart';
import 'package:fullxpet/locator.dart';

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
  final HttpClient _httpClient = locator.get();
  final MqttManager _mqttManager = locator.get();

  /// 底表 1：产品列表缓存表 (key = productId)
  final ProductCacheMap _productCache = {};

  /// 底表 2：设备列表基础信息缓存表 (key = deviceId)
  final DeviceBasicCacheMap _deviceBasicCache = {};

  /// 底表 3：单台设备 DPID 属性状态底表 (key = deviceId, value = {dpid: 清洗后的真实值})
  final DeviceDpidCacheMap _deviceDpidCache = {};

  /// 附加底表：单台设备硬件与网络信息表 (key = deviceId, 存 ssid/rssi/mcuVersion/imei 等)
  final DeviceHardwareCacheMap _deviceHardwareCache = {};

  /// 设备数据变更广播流（发送变更的 deviceId；若列表整体刷新则发送 'ALL'）
  final StreamController<String> _deviceUpdateController = StreamController.broadcast();
  Stream<String> get onDeviceUpdated => _deviceUpdateController.stream;

  StreamSubscription? _mqttSub;
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
  Future<ResultEntity<ProductDtoList>> fetchProducts({bool forceRefresh = false}) async {
    if (_productCache.isNotEmpty && !forceRefresh) {
      return ResultEntity.success(cachedProducts);
    }
    try {
      final response = await _httpClient.get(ApiEndpoints.products);
      final data = response.data;
      if ((response.code == 0 || response.code == 200) && data is Map) {
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
        return ResultEntity.success(cachedProducts);
      }
      return ResultEntity.error(response.message);
    } catch (e) {
      return ResultEntity.error('拉取产品列表失败: $e');
    }
  }

  /// 拉取设备列表 -> 自动存入 _deviceBasicCache
  Future<ResultEntity<DeviceItemDtoList>> getDeviceList() async {
    try {
      if (_productCache.isEmpty) {
        await fetchProducts();
      }
      final result = await _httpClient.get(ApiEndpoints.devices);
      final data = result.data;
      if (data is Map && (result.code == 0 || result.code == 200)) {
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
        _notify('ALL');
        return ResultEntity.success(cachedDeviceList);
      }
      return ResultEntity.error(result.message);
    } catch (e) {
      return ResultEntity.error('拉取设备列表失败: $e');
    }
  }

  /// 拉取单台设备全量属性 -> 自动存入 _deviceDpidCache 与 _deviceHardwareCache
  Future<ResultEntity<DevicePropertiesDto>> fetchDeviceProperties(String deviceId) async {
    try {
      final result = await _httpClient.get(ApiEndpoints.deviceProperties(deviceId));
      final data = result.data;
      if (data is Map && (result.code == 0 || result.code == 200)) {
        final dto = DevicePropertiesDto.fromJson(data);

        final existingBasic = _deviceBasicCache[deviceId];
        if (existingBasic != null && existingBasic.online != dto.online) {
          _deviceBasicCache[deviceId] = existingBasic.copyWith(online: dto.online);
        }

        _deviceHardwareCache[deviceId] = dto.deviceInfo;
        _deviceDpidCache[deviceId] = dto.toDpidMap();

        _notify(deviceId);
        return ResultEntity.success(dto);
      }
      return ResultEntity.error(result.message);
    } catch (e) {
      return ResultEntity.error('拉取设备属性失败 [$deviceId]:$e');
    }
  }

  /// 下发 DPID 控制指令
  Future<bool> sendDeviceCommand(String deviceId, CommandAttrList attributes) async {
    try {
      final result = await _httpClient.post(ApiEndpoints.deviceInvoke(deviceId), data: {'attributes': attributes});
      return result.code == 0 || result.code == 200;
    } catch (e) {
      debugPrint('发送指令失败 [$deviceId]:$e');
      return false;
    }
  }

  /// 修改设备名称 -> 成功后直接更新底表 2 并广播
  Future<bool> renameDevice(String deviceId, String newName) async {
    try {
      final result = await _httpClient.patch(ApiEndpoints.deviceName(deviceId), data: {'nickname': newName});
      if (result.code == 0 || result.code == 200) {
        final existing = _deviceBasicCache[deviceId];
        if (existing != null) {
          _deviceBasicCache[deviceId] = existing.copyWith(nickname: newName);
        }
        _notify(deviceId);
        return true;
      }
      return false;
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
        final homeList = await _httpClient.get(ApiEndpoints.homeList);
        final listData = homeList.data;
        if (listData is Map && listData['items'] is List && (listData['items'] as List).isNotEmpty) {
          homeId = listData['items'][0]['id']?.toString() ?? '';
        }
      }
      if (homeId.isEmpty) return false;

      final res = await _httpClient.delete(ApiEndpoints.deviceUnBind(homeId, deviceId));
      if (res.code == 0 || res.code == 200) {
        _deviceBasicCache.remove(deviceId);
        _deviceDpidCache.remove(deviceId);
        _deviceHardwareCache.remove(deviceId);
        _notify('ALL');
        return true;
      }
    } catch (e) {
      debugPrint('删除设备失败 [$deviceId]:$e');
    }
    return false;
  }

  /// 通用日志拉取
  Future<ResultEntity<JsonMap>> fetchDeviceLogsRaw(
    String deviceId, {
    required String dpidFilter,
    required String fromIsoUtc,
    required String toIsoUtc,
    int pageSize = 20,
    String sort = 'desc',
    String? pageToken,
  }) async {
    try {
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
      final result = await _httpClient.get(ApiEndpoints.deviceLogs(deviceId), query: query);
      if (result.data is Map && (result.code == 0 || result.code == 200)) {
        return ResultEntity.success(JsonMap.from(result.data as Map));
      }
      return ResultEntity.error(result.message);
    } catch (e) {
      return ResultEntity.error('获取设备日志失败: $e');
    }
  }

  /// 检查设备是否有待升级固件
  Future<JsonMap?> checkPendingFirmware(String deviceId) async {
    try {
      final res = await _httpClient.get(ApiEndpoints.checkFirmware(deviceId));
      if ((res.code == 0 || res.code == 200) && res.data != null) {
        final rawData = res.data;
        if (rawData is List && rawData.isNotEmpty) {
          return JsonMap.from(rawData.first as Map);
        } else if (rawData is Map) {
          return JsonMap.from(rawData);
        }
      }
    } catch (_) {}
    return null;
  }

  /// 下发固件升级指令
  Future<bool> dispatchFirmwareUpgrade(String deviceId, String recordId) async {
    try {
      final result = await _httpClient.post(ApiEndpoints.upgradeFirmware(deviceId, recordId));
      return result.code == 0 || result.code == 200;
    } catch (e) {
      debugPrint('下发固件升级指令失败 [$deviceId]:$e');
      return false;
    }
  }

  /// 获取设备视频直播参数
  Future<ResultEntity<FeederLiveInfo>> fetchLiveInfo(String deviceId, {int camera = 0, int resolution = 0}) async {
    try {
      final String platform = Platform.isIOS ? 'ios' : 'android';
      final String clientInstanceId = _getValidClientInstanceId();
      final JsonMap payload = {
        'clientInstanceId': clientInstanceId,
        'platform': platform,
        'camera': camera,
        'resolution': resolution,
      };
      final res = await _httpClient.post(ApiEndpoints.deviceLiveVideo(deviceId), data: payload);
      if (res.data is Map && (res.code == 0 || res.code == 200)) {
        return ResultEntity.success(FeederLiveInfo.fromJson(JsonMap.from(res.data as Map)));
      }
      return ResultEntity.error(res.message);
    } catch (e) {
      return ResultEntity.error('获取视频直播参数异常: $e');
    }
  }

  /// 获取 MQTT 凭证
  Future<ResultEntity<JsonMap>> fetchMqttCredentials() async {
    try {
      final res = await _httpClient.post(ApiEndpoints.mqttCredentials);
      if (res.data is Map && (res.code == 0 || res.code == 200)) {
        return ResultEntity.success(JsonMap.from(res.data as Map));
      }
      return ResultEntity.error(res.message);
    } catch (e) {
      return ResultEntity.error('获取 MQTT 凭证异常: $e');
    }
  }

  /// 一键同步 MQTT 订阅
  Future<bool> syncMqttSubscriptions() async {
    try {
      final res = await _httpClient.post(ApiEndpoints.mqttSubscribeSync);
      return res.code == 0 || res.code == 200;
    } catch (e) {
      debugPrint('一键同步订阅失败: $e');
      return false;
    }
  }

  /// 清空三张底表（退出登录时调用）
  void clearPool() {
    _productCache.clear();
    _deviceBasicCache.clear();
    _deviceDpidCache.clear();
    _deviceHardwareCache.clear();
  }

  void _notify(String deviceId) {
    _deviceUpdateController.add(deviceId);
  }

  String _getValidClientInstanceId() {
    if (_cachedClientInstanceId != null && _clientInstanceIdRegex.hasMatch(_cachedClientInstanceId!)) {
      return _cachedClientInstanceId!;
    }
    String generatedId = UuidsTool.generateStandardUUID();
    if (!_clientInstanceIdRegex.hasMatch(generatedId)) {
      final cleanHex = generatedId.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
      if (cleanHex.length == 32) {
        generatedId = cleanHex;
      }
    }
    _cachedClientInstanceId = generatedId;
    return generatedId;
  }

  void _startListeningMqtt() {
    _mqttSub = _mqttManager.messageStream.listen((data) {
      debugPrint('[MQTT 原始消息]: $data');
      final type = data['type']?.toString();
      if (type != 'attr_report') return;

      final report = MqttAttrReportDto.fromJson(JsonMap.from(data));
      if (report.deviceId.isNotEmpty && report.effectiveChanges.isNotEmpty) {
        final dpidMap = _deviceDpidCache.putIfAbsent(report.deviceId, () => {});
        report.effectiveChanges.forEach((dpid, value) {
          dpidMap[dpid] = value;
        });
        _notify(report.deviceId);
      }
    });
  }

  void dispose() {
    _mqttSub?.cancel();
    _deviceUpdateController.close();
  }
}
