import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/core/hardware/mqtt_manager.dart';
import 'package:fullxpet/core/services/nav_service.dart';
import 'package:fullxpet/features/device/models/device_dto.dart';
import 'package:fullxpet/features/device/repositories/device_repository.dart';
import 'package:fullxpet/locator.dart';

class DeviceProvider extends BaseProvider {
  final DeviceRepository _deviceRepo = locator<DeviceRepository>();
  List<DeviceDto> _devices = [];
  List<DeviceDto> get devices => _devices;
  StreamSubscription<String>? _repoSubscription;

  // 记录上次成功订阅的设备 ID 集合
  Set<String> _subscribedDeviceIds = {};

  DeviceProvider() {
    _repoSubscription = _deviceRepo.onDeviceUpdated.listen((updatedDeviceId) {
      if (_devices.any((d) => d.deviceId == updatedDeviceId)) {
        notifyListeners();
      }
    });
  }

  // 统一从全局 context 获取多语言实例
  S? get _s {
    final BuildContext? ctx = NavService.rootNavigatorKey.currentContext;
    return ctx != null ? S.of(ctx) : null;
  }

  @override
  void dispose() {
    _repoSubscription?.cancel();
    super.dispose();
  }

  // 拉取设备列表
  Future<void> fetchDevices() async {
    setLoading(true);
    clearError();
    try {
      final result = await _deviceRepo.getDeviceList();
      if (result.data != null) {
        _devices = result.data!;
        _checkAndSyncMqttSubscriptions();
      } else {
        setError(result.message);
      }
      notifyListeners();
    } catch (_) {
      setError(_s?.networkError ?? "网络连接失败，请检查网络设置");
    } finally {
      if (isLoading) setLoading(false);
    }
  }

  // 修改设备名称
  Future<bool> renameDevice(String deviceId, String newName) async {
    setLoading(true);
    final success = await _deviceRepo.renameDevice(deviceId, newName);
    setLoading(false);
    if (!success) {
      setError(_s?.operationFailed ?? "更新名称失败");
    }
    return success;
  }

  // 检查 MQTT 连接与订阅
  Future<void> _checkAndSyncMqttSubscriptions() async {
    if (_devices.isEmpty) return;

    final currentDeviceIds = _devices.map((d) => d.deviceId).toSet();
    final mqttManager = locator<MqttManager>();

    // 若 MQTT 未连接，先完成认证连接并全量同步
    if (!mqttManager.isConnected) {
      await _initGlobalMqttAndSubscribe();
      _subscribedDeviceIds = currentDeviceIds;
      return;
    }

    // 若已连接且设备 ID 列表完全没有变化，直接跳过请求
    final bool isListUnchanged =
        _subscribedDeviceIds.length == currentDeviceIds.length && _subscribedDeviceIds.containsAll(currentDeviceIds);

    if (isListUnchanged) {
      return;
    }

    // 设备数量或 ID 有变动，向云端一键同步最新订阅池
    await _subscribeAllDevices();
    _subscribedDeviceIds = currentDeviceIds;
  }

  // 获取 MQTT 动态连接凭证
  Future<void> _initGlobalMqttAndSubscribe() async {
    if (_devices.isEmpty) return;

    final credResult = await _deviceRepo.fetchMqttCredentials();
    if (credResult.data == null) {
      debugPrint('获取 MQTT 凭证失败: ${credResult.message}');
      return;
    }

    final mqttData = credResult.data!['mqtt'];
    if (mqttData == null) return;

    final bool isConnected = await locator<MqttManager>().connect(
      endpoint: mqttData['endpoint'],
      port: int.tryParse(mqttData['port'].toString()) ?? 8883,
      username: mqttData['username'],
      password: mqttData['password'],
      clientId: mqttData['clientIdHint'],
      subscribeTopic: mqttData['subscribeTopic'],
      useTls: mqttData['tls'].toString() == 'true',
    );

    if (isConnected) {
      await _subscribeAllDevices();
    }
  }

  // 订阅所有设备的主题
  Future<void> _subscribeAllDevices() async {
    final success = await _deviceRepo.syncMqttSubscriptions();
    if (success) {
      debugPrint('一键同步订阅所有设备成功');
    } else {
      debugPrint('一键同步订阅失败');
    }
  }

  // 删除&解绑设备
  Future<bool> deleteDevice(String deviceId) async {
    setLoading(true);
    clearError();
    try {
      final success = await _deviceRepo.deleteDevice(deviceId);
      if (success) {
        _devices.removeWhere((d) => d.deviceId == deviceId);
        _subscribedDeviceIds.remove(deviceId);
        notifyListeners();
        return true;
      } else {
        setError(_s?.deleteFailed ?? "删除设备失败，请稍后重试");
      }
    } catch (_) {
      setError(_s?.deleteFailed ?? "删除设备失败，请稍后重试");
    } finally {
      setLoading(false);
    }
    return false;
  }
}
