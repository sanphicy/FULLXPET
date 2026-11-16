import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fullxpet/common/providers/user_provider.dart';
import 'package:fullxpet/core/network/api_client.dart';
import 'package:fullxpet/core/network/api_endpoints.dart';
import 'package:fullxpet/features/device/models/product_dto.dart';
import 'package:fullxpet/features/device/repositories/device_repository.dart';
import 'package:fullxpet/locator.dart';
import '../models/discovered_device.dart';

typedef ProductDtoList = List<ProductDto>;
typedef JsonMap = Map<String, dynamic>;

class DeviceAddRepository {
  final Dio _dio = locator<ApiClient>().dio;
  final DeviceRepository _deviceRepo = locator<DeviceRepository>();

  String? _cachedHomeId;
  String? _cachedRoomId;

  /// 直接读取全局 DeviceRepository 的底表 1 (产品缓存表)
  ProductDtoList get cachedProducts => _deviceRepo.cachedProducts;

  /// 1. 复用全局 DeviceRepository 拉取并缓存产品列表
  Future<ProductDtoList> fetchProductList({bool forceRefresh = false}) async {
    try {
      return await _deviceRepo.fetchProducts(forceRefresh: forceRefresh);
    } catch (e) {
      debugPrint("拉取产品列表失败: $e");
      return _deviceRepo.cachedProducts;
    }
  }

  /// 2. 复用底表 1：拿骏云广播 2 字节短 ID (productShortId) 查找产品 DTO
  ProductDto? findProductByShortId(String shortId) => _deviceRepo.findProductByShortId(shortId);

  /// 3. 复用底表 1：拿完整 productId 查找产品 DTO
  ProductDto? findProductByFullId(String productId) => _deviceRepo.getProduct(productId);

  /// 4. 构建扫描列表设备：区分 junvine 与 hooget 配网方式
  DiscoveredDevice buildDiscoveredDevice({
    required String id,
    required String name,
    required int rssi,
    required BluetoothDevice device,
    required String parsedMac,
    required String parsedShortPid,
  }) {
    if (parsedShortPid.isNotEmpty) {
      final matchedProduct = findProductByShortId(parsedShortPid);
      final resolvedPid = matchedProduct?.productId ?? '';

      return DiscoveredDevice(
        id: id,
        name: name,
        rssi: rssi,
        device: device,
        mac: parsedMac,
        shortPid: parsedShortPid,
        pid: resolvedPid,
        iconUrl: matchedProduct?.thumbnailUrl,
        fallbackAsset: HoogetProductCatalog.resolveFallbackAsset(name, resolvedPid),
        provisionMode: ProvisionMode.junvine,
      );
    }

    final hardcodedPid = HoogetProductCatalog.matchProductIdByName(name);
    final matchedProduct = findProductByFullId(hardcodedPid);

    return DiscoveredDevice(
      id: id,
      name: name,
      rssi: rssi,
      device: device,
      mac: parsedMac,
      shortPid: '',
      pid: hardcodedPid,
      iconUrl: matchedProduct?.thumbnailUrl,
      fallbackAsset: HoogetProductCatalog.resolveFallbackAsset(name, hardcodedPid),
      provisionMode: ProvisionMode.hooget,
    );
  }

  /// 5. 获取设备 MQTT / 注册地址（hooget 拼接 mqtts://，junvine 不拼前缀）
  Future<String?> getDeviceMqttRui({required ProvisionMode mode}) async {
    final String countryCode = locator<UserProvider>().user.countryCode;
    try {
      final payload = {"countryCode": countryCode, "clientAppId": "fullxpet"};
      final response = await _dio.get(ApiEndpoints.mqttUri, queryParameters: payload);
      final data = response.data;
      if (data is Map) {
        if (data['deviceMqttEndpoint'] != null && data['deviceMqttPort'] != null) {
          final endpoint = data['deviceMqttEndpoint'];
          final port = data['deviceMqttPort'];
          if (mode == ProvisionMode.hooget) {
            return "mqtts://$endpoint:$port";
          }
          return "$endpoint:$port";
        }
      }
      return null;
    } catch (e) {
      debugPrint("获取设备MQTT配置异常: $e");
      return null;
    }
  }

  /// 生成候选 MAC 队列
  List<String> _buildCandidateMacs(String baseMac) {
    final clean = baseMac.trim().toUpperCase();
    if (clean.isEmpty) return [];

    final Set<String> candidates = {clean, clean.replaceAll(':', '')};
    final parts = clean.split(':');
    if (parts.length == 6) {
      final int? lastByte = int.tryParse(parts[5], radix: 16);
      if (lastByte != null) {
        for (final int delta in [-2, -1, 1, 2]) {
          final int derived = (lastByte + delta) & 0xFF;
          final String derivedHex = derived.toRadixString(16).padLeft(2, '0').toUpperCase();
          final String withColons = [...parts.sublist(0, 5), derivedHex].join(':');
          candidates.add(withColons);
          candidates.add(withColons.replaceAll(':', ''));
        }
      }
    }
    return candidates.toList();
  }

  /// 6. 向云端轮询绑定设备
  Future<bool> bindDeviceToCloud({
    required String mac,
    required String pid,
    required String nickname,
    required ProvisionMode mode,
  }) async {
    final String cleanMac = mac.trim();
    final String cleanPid = pid.trim();
    if (cleanMac.isEmpty || cleanPid.isEmpty) {
      debugPrint("【绑定拦截】MAC($cleanMac) 或 PID($cleanPid) 为空，无法向云端发起绑定");
      return false;
    }

    try {
      if (_cachedHomeId == null || _cachedHomeId!.isEmpty) {
        final homeListRes = await _dio.get(ApiEndpoints.homeList);
        final listData = homeListRes.data;
        final items = (listData is Map) ? listData['items'] as List? : null;
        if (items == null || items.isEmpty) return false;

        _cachedHomeId = items[0]['id']?.toString() ?? '';
        final homeInfo = await _dio.get(ApiEndpoints.homeInfo(_cachedHomeId!));

        final infoData = homeInfo.data;
        if (infoData is Map && infoData['rooms'] is List) {
          final List rooms = infoData['rooms'];
          if (rooms.isNotEmpty) {
            _cachedRoomId = rooms[0]['id']?.toString() ?? '';
          }
        }
      }

      final String homeId = _cachedHomeId ?? '';
      final String roomId = _cachedRoomId ?? '';
      if (homeId.isEmpty) return false;

      final String effectiveNickname = nickname.isNotEmpty ? nickname : "FULLXPET";

      if (mode == ProvisionMode.hooget) {
        final JsonMap bindPayload = {
          "hardwareId": cleanMac,
          "productId": cleanPid,
          "roomId": roomId,
          "nickname": effectiveNickname,
          "bindSource": Platform.isAndroid ? "android" : "ios",
          "locallyBound": false,
        };

        final DateTime endTime = DateTime.now().add(const Duration(minutes: 1));
        while (DateTime.now().isBefore(endTime)) {
          try {
            await _dio.post(ApiEndpoints.deviceBind(homeId), data: bindPayload);
            return true;
          } catch (_) {}
          await Future.delayed(const Duration(seconds: 3));
        }
        return false;
      }

      final List<String> macCandidates = _buildCandidateMacs(cleanMac);
      final DateTime endTime = DateTime.now().add(const Duration(seconds: 55));
      int attempt = 0;

      while (DateTime.now().isBefore(endTime)) {
        final String currentMac = (attempt < 2 || macCandidates.isEmpty)
            ? cleanMac
            : macCandidates[attempt % macCandidates.length];

        try {
          final JsonMap bindPayload = {
            "hardwareId": currentMac,
            "productId": cleanPid,
            "roomId": roomId,
            "nickname": effectiveNickname,
            "bindSource": Platform.isAndroid ? "android" : "ios",
            "locallyBound": false,
          };

          await _dio.post(ApiEndpoints.deviceBind(homeId), data: bindPayload);
          debugPrint("【绑定成功】生效 hardwareId: $currentMac, productId:$cleanPid");
          return true;
        } catch (_) {}

        attempt++;
        await Future.delayed(const Duration(seconds: 2));
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
