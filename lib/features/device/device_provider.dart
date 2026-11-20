import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/core/hardware/mqtt_manager.dart';
import 'package:fullxpet/core/network/api_exception.dart';
import 'package:fullxpet/core/services/nav_service.dart';
import 'package:fullxpet/core/utils/device_batch_helper.dart';
import 'package:fullxpet/features/device/models/device_item_dto.dart';
import 'package:fullxpet/features/device/models/product_dto.dart';
import 'package:fullxpet/features/device/products/feeder/models/feeder_thing_model.dart';
import 'package:fullxpet/features/device/products/litter_box/models/device_thing_model.dart';
import 'package:fullxpet/features/device/repositories/device_repository.dart';
import 'package:fullxpet/locator.dart';
import 'package:fullxpet/features/device/constants/product_constants.dart';

/// 通用筛选胶囊模型（一级大类与二级子型号）
class DeviceFilterTab {
  final String key;
  final String label;
  final int count;

  const DeviceFilterTab({required this.key, required this.label, required this.count});
}

/// 卡片底部动态数据微摘要徽章
class DeviceCardBadge {
  final IconData icon;
  final String text;
  final bool isHighlight;

  const DeviceCardBadge({required this.icon, required this.text, this.isHighlight = false});
}

typedef FilterTabList = List<DeviceFilterTab>;
typedef CardBadgeList = List<DeviceCardBadge>;
typedef StringList = List<String>;
typedef StringSet = Set<String>;

class DeviceProvider extends BaseProvider {
  final DeviceRepository _deviceRepo = locator.get();

  String _selectedCategoryKey = 'ALL';
  String _selectedProductId = 'ALL';
  bool _isGridView = false;
  StreamSubscription? _repoSub;
  StringSet _subscribedDeviceIds = {};

  String get selectedCategoryKey => _selectedCategoryKey;
  String get selectedProductId => _selectedProductId;
  bool get isGridView => _isGridView;

  DeviceProvider() {
    _repoSub = _deviceRepo.onDeviceUpdated.listen((updatedId) {
      if (updatedId == 'ALL' || devices.any((d) => d.deviceId == updatedId)) {
        notifyListeners();
      }
    });
  }

  S? get _s {
    final BuildContext? ctx = NavService.rootNavigatorKey.currentContext;
    return ctx != null ? S.of(ctx) : null;
  }

  @override
  void dispose() {
    _repoSub?.cancel();
    super.dispose();
  }

  /// 获取当前全部设备列表（在线优先，其次按 sortOrder）
  DeviceItemDtoList get devices {
    final list = List.of(_deviceRepo.cachedDeviceList);
    list.sort((a, b) {
      final onlineCmp = (b.online ? 1 : 0).compareTo(a.online ? 1 : 0);
      if (onlineCmp != 0) return onlineCmp;
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return list;
  }

  int get onlineCount => devices.where((d) => d.online).length;
  int get offlineCount => devices.length - onlineCount;

  String resolveCategoryCode(DeviceItemDto item) {
    final prod = _deviceRepo.getProduct(item.productId);
    if (prod != null && prod.categoryCode.trim().isNotEmpty) {
      return prod.categoryCode.trim().toLowerCase();
    }
    if (item.category.trim().isNotEmpty) {
      return item.category.trim().toLowerCase();
    }
    if (item.miniAppId.trim().isNotEmpty) {
      return item.miniAppId.trim().toLowerCase();
    }
    return 'other';
  }

  FilterTabList get categoryTabs {
    final all = devices;
    if (all.isEmpty) return const [];

    final Map countMap = {};
    final Map namesInGroup = {};

    for (final dev in all) {
      final String catCode = resolveCategoryCode(dev);
      countMap[catCode] = (countMap[catCode] as int? ?? 0) + 1;

      final prod = _deviceRepo.getProduct(dev.productId);
      final String prodName = (prod != null && prod.name.trim().isNotEmpty) ? prod.name.trim() : dev.nickname.trim();

      final StringList list = namesInGroup.putIfAbsent(catCode, () => <String>[]) as StringList;
      if (prodName.isNotEmpty && !list.contains(prodName)) {
        list.add(prodName);
      }
    }

    for (final prod in _deviceRepo.cachedProducts) {
      final code = prod.categoryCode.trim().toLowerCase();
      if (namesInGroup.containsKey(code) && prod.name.trim().isNotEmpty) {
        final StringList list = namesInGroup[code] as StringList;
        if (!list.contains(prod.name.trim())) {
          list.add(prod.name.trim());
        }
      }
    }

    final FilterTabList tabs = [DeviceFilterTab(key: 'ALL', label: '全部', count: all.length)];

    countMap.forEach((key, count) {
      final String catCode = key.toString();
      final StringList candidateNames = (namesInGroup[catCode] as StringList?) ?? const [];
      final String label = _computeCategoryLabel(candidateNames, catCode);
      tabs.add(DeviceFilterTab(key: catCode, label: label, count: count as int));
    });

    return tabs;
  }

  FilterTabList get subProductTabs {
    if (_selectedCategoryKey == 'ALL') return const [];

    final categoryDevices = devices.where((d) => resolveCategoryCode(d) == _selectedCategoryKey).toList();
    if (categoryDevices.length <= 1) return const [];

    final Map countByPid = {};
    final Map labelByPid = {};

    for (final dev in categoryDevices) {
      final pid = dev.productId.trim();
      if (pid.isEmpty) continue;
      countByPid[pid] = (countByPid[pid] as int? ?? 0) + 1;

      final prod = _deviceRepo.getProduct(pid);
      labelByPid.putIfAbsent(
        pid,
        () => (prod != null && prod.name.trim().isNotEmpty)
            ? prod.name.trim()
            : (prod != null && prod.modelCode.isNotEmpty ? prod.modelCode : dev.nickname),
      );
    }

    if (countByPid.length < 2) return const [];

    final FilterTabList subTabs = [DeviceFilterTab(key: 'ALL', label: '全部型号', count: categoryDevices.length)];

    countByPid.forEach((pid, count) {
      subTabs.add(
        DeviceFilterTab(key: pid.toString(), label: labelByPid[pid]?.toString() ?? pid.toString(), count: count as int),
      );
    });

    return subTabs;
  }

  DeviceItemDtoList get filteredDevices {
    final all = devices;
    if (_selectedCategoryKey == 'ALL') return all;

    return all.where((dev) {
      final matchCat = resolveCategoryCode(dev) == _selectedCategoryKey;
      if (!matchCat) return false;
      if (_selectedProductId == 'ALL') return true;
      return dev.productId.trim() == _selectedProductId;
    }).toList();
  }

  void selectCategory(String categoryKey) {
    if (_selectedCategoryKey == categoryKey && _selectedProductId == 'ALL') return;
    _selectedCategoryKey = categoryKey;
    _selectedProductId = 'ALL';
    notifyListeners();
  }

  void selectSubProduct(String productIdKey) {
    if (_selectedProductId == productIdKey) return;
    _selectedProductId = productIdKey;
    notifyListeners();
  }

  void toggleLayoutMode() {
    _isGridView = !_isGridView;
    notifyListeners();
  }

  String _computeCategoryLabel(StringList names, String fallbackCode) {
    if (names.isEmpty) return fallbackCode;
    if (names.length == 1) return names.first;

    String common = names.first;
    for (int i = 1; i < names.length; i++) {
      common = _longestCommonSubstring(common, names[i]).trim();
      if (common.isEmpty) break;
    }

    if (common.length >= 2) {
      return common;
    }
    return names.first;
  }

  String _longestCommonSubstring(String s1, String s2) {
    int maxLen = 0;
    int endIndex = 0;
    final List dp = List.generate(s1.length + 1, (_) => List.filled(s2.length + 1, 0));

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        if (s1[i - 1] == s2[j - 1]) {
          final int prev = dp[i - 1][j - 1] as int;
          final int cur = prev + 1;
          dp[i][j] = cur;
          if (cur > maxLen) {
            maxLen = cur;
            endIndex = i;
          }
        }
      }
    }
    return s1.substring(endIndex - maxLen, endIndex);
  }

  CardBadgeList resolveDeviceBadges(DeviceItemDto item) {
    final DpidValueMap dpidMap = _deviceRepo.getDeviceDpidMap(item.deviceId);
    if (dpidMap.isEmpty) return const [];

    final CardBadgeList badges = [];
    final bool isFeeder = ProductConstants.isFeeder(item.productId);
    final bool isLitterBox = ProductConstants.isLitterBox(item.productId);
    if (isFeeder) {
      final rawTimes = dpidMap[FeederThingModel.excretionTimesDay.dpid];
      if (rawTimes != null) {
        final int times = int.tryParse(rawTimes.toString()) ?? 0;
        badges.add(DeviceCardBadge(icon: Icons.restaurant_rounded, text: '今日进食 $times 次', isHighlight: true));
      }

      String modeText = '';
      if (dpidMap[FeederThingModel.autoMode.dpid] == true) {
        modeText = '猫脸识别';
      } else if (dpidMap[FeederThingModel.semiautomode.dpid] == true) {
        modeText = '红外模式';
      } else if (dpidMap[FeederThingModel.gapingMode.dpid] == true) {
        final isTimer = dpidMap[FeederThingModel.delayMode.dpid] == true;
        modeText = isTimer ? '定时+敞开' : '敞开模式';
      }
      if (modeText.isNotEmpty) {
        badges.add(DeviceCardBadge(icon: Icons.tune_rounded, text: modeText));
      }
      return badges;
    }

    if (isLitterBox) {
      final rawTimes = dpidMap[DeviceThingModel.excretionTimesDay.dpid];
      if (rawTimes != null) {
        final int times = int.tryParse(rawTimes.toString()) ?? 0;
        badges.add(DeviceCardBadge(icon: Icons.pets_rounded, text: '今日 $times 次', isHighlight: true));
      }

      // 严格通过 productId 判断是否为 V4
      final bool isV4Model = item.productId == ProductConstants.pidLitterBoxV4;

      if (!isV4Model) {
        final rawLitterWeight = dpidMap[DeviceThingModel.litterWeight.dpid];
        if (rawLitterWeight != null) {
          final int grams = int.tryParse(rawLitterWeight.toString()) ?? -1;
          if (grams >= 0) {
            final String weightStr = grams >= 1000 ? '${(grams / 1000.0).toStringAsFixed(1)}kg' : '${grams}g';
            badges.add(DeviceCardBadge(icon: Icons.scale_rounded, text: '余砂 $weightStr'));
          }
        }

        final rawShitWeight = dpidMap[DeviceThingModel.shitWeight.dpid];
        if (rawShitWeight != null) {
          final int shitGrams = int.tryParse(rawShitWeight.toString()) ?? -1;
          if (shitGrams >= 0) {
            badges.add(DeviceCardBadge(icon: Icons.delete_outline_rounded, text: '便仓 ${shitGrams}g'));
          }
        }
      }

      if (badges.length < 3 && dpidMap.containsKey(DeviceThingModel.deviceMode.dpid)) {
        final int modeVal = int.tryParse(dpidMap[DeviceThingModel.deviceMode.dpid].toString()) ?? 0;
        final String modeLabel = switch (modeVal) {
          1 => '定时模式',
          2 => '手动模式',
          _ => '自动模式',
        };
        badges.add(DeviceCardBadge(icon: Icons.autorenew_rounded, text: modeLabel));
      }

      return badges;
    }

    return badges;
  }

  Future<void> fetchDevices() async {
    setLoading(true);
    clearError();
    try {
      await _deviceRepo.getDeviceList();
      _ensureSelectionValid();
      unawaited(_prefetchAllDeviceProperties());
      unawaited(_checkAndSyncMqttSubscriptions());
      notifyListeners();
    } catch (e) {
      setError(ApiException.from(e).message);
    } finally {
      if (isLoading) setLoading(false);
    }
  }

  Future<void> _prefetchAllDeviceProperties() async {
    final list = devices;
    if (list.isEmpty) return;
    await Future.wait(list.map((d) => _deviceRepo.fetchDeviceProperties(d.deviceId)));
  }

  Future<bool> renameDevice(String deviceId, String newName) async {
    setLoading(true);
    final success = await _deviceRepo.renameDevice(deviceId, newName);
    setLoading(false);
    if (!success) {
      setError(_s?.operationFailed ?? '更新名称失败');
    }
    return success;
  }

  Future<bool> deleteDevice(String deviceId) async {
    setLoading(true);
    clearError();
    try {
      final success = await _deviceRepo.deleteDevice(deviceId);
      if (success) {
        _subscribedDeviceIds.remove(deviceId);
        _ensureSelectionValid();
        notifyListeners();
        return true;
      } else {
        setError(_s?.deleteFailed ?? '删除设备失败，请稍后重试');
      }
    } catch (_) {
      setError(_s?.deleteFailed ?? '删除设备失败，请稍后重试');
    } finally {
      setLoading(false);
    }
    return false;
  }

  void _ensureSelectionValid() {
    if (_selectedCategoryKey != 'ALL') {
      final catExists = categoryTabs.any((t) => t.key == _selectedCategoryKey);
      if (!catExists) {
        _selectedCategoryKey = 'ALL';
        _selectedProductId = 'ALL';
        return;
      }
    }
    if (_selectedProductId != 'ALL') {
      final subExists = subProductTabs.any((t) => t.key == _selectedProductId);
      if (!subExists) {
        _selectedProductId = 'ALL';
      }
    }
  }

  String resolveImageUrl(DeviceItemDto item) {
    if (item.iconUrl.isNotEmpty) return item.iconUrl;
    final ProductDto? prod = _deviceRepo.getProduct(item.productId);
    return prod?.thumbnailUrl ?? '';
  }

  String resolveProductName(DeviceItemDto item) {
    final ProductDto? prod = _deviceRepo.getProduct(item.productId);
    if (prod != null && prod.name.isNotEmpty) return prod.name;
    return '';
  }

  String resolveModelCode(DeviceItemDto item) {
    final ProductDto? prod = _deviceRepo.getProduct(item.productId);
    if (prod != null && prod.modelCode.isNotEmpty) return prod.modelCode;
    return '';
  }

  String resolveDisplayId(DeviceItemDto item) => DeviceBatchHelper().getDisplayBatchNo(item.deviceId);

  Future<void> _checkAndSyncMqttSubscriptions() async {
    final list = devices;
    if (list.isEmpty) return;

    final currentDeviceIds = list.map((d) => d.deviceId).toSet();
    final mqttManager = locator.get<MqttManager>();

    if (!mqttManager.isConnected) {
      await _initGlobalMqttAndSubscribe();
      _subscribedDeviceIds = currentDeviceIds;
      return;
    }

    final bool isListUnchanged =
        _subscribedDeviceIds.length == currentDeviceIds.length && _subscribedDeviceIds.containsAll(currentDeviceIds);
    if (isListUnchanged) return;

    await _deviceRepo.syncMqttSubscriptions();
    _subscribedDeviceIds = currentDeviceIds;
  }

  Future<void> _initGlobalMqttAndSubscribe() async {
    try {
      final credMap = await _deviceRepo.fetchMqttCredentials();
      final mqttData = credMap['mqtt'];
      if (mqttData is! Map) return;

      final bool isConnected = await locator.get<MqttManager>().connect(
        endpoint: mqttData['endpoint']?.toString() ?? '',
        port: int.tryParse(mqttData['port'].toString()) ?? 8883,
        username: mqttData['username']?.toString() ?? '',
        password: mqttData['password']?.toString() ?? '',
        clientId: mqttData['clientIdHint']?.toString() ?? '',
        subscribeTopic: mqttData['subscribeTopic']?.toString() ?? '',
        useTls: mqttData['tls'].toString() == 'true',
      );
      if (isConnected) {
        await _deviceRepo.syncMqttSubscriptions();
      }
    } catch (e) {
      debugPrint('初始化 MQTT 凭证及连接失败: $e');
    }
  }
}
