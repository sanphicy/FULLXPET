import 'dart:async';
import 'package:fullxpet/locator.dart';
import 'package:flutter/material.dart';
import 'package:fullxpet/core/mqtt/mqtt_manager.dart';
import 'package:fullxpet/core/network/http_client.dart';
import 'package:fullxpet/core/network/api_endpoints.dart';
import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/features/device/models/device_dto.dart';
import 'package:fullxpet/features/device/repositories/device_repository.dart';

class DeviceProvider extends BaseProvider {
  //设备仓库实例
  final DeviceRepository _deviceRepo = locator<DeviceRepository>();
  List<DeviceDto> _devices = [];
  List<DeviceDto> get devices => _devices;
  StreamSubscription<String>? _repoSubscription;

  DeviceProvider() {
    // 监听底层设备池的更新，如果变动的设备在列表中，则刷新 UI
    _repoSubscription = _deviceRepo.onDeviceUpdated.listen((updatedDeviceId) {
      if (_devices.any((d) => d.deviceId == updatedDeviceId)) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _repoSubscription?.cancel();
    super.dispose();
  }

  // 获取设备列表
  Future<void> fetchDevices() async {
    setLoading(true);
    clearError();
    try {
      _devices = await _deviceRepo.getDeviceList();
      _initGlobalMqttAndSubscribe();
      notifyListeners();
    } catch (e) {
      setError("网络连接失败，请检查网络设置");
    } finally {
      if (isLoading) setLoading(false);
    }
  }

  // 修改设备名称 (设备列表页调用)
  Future<bool> renameDevice(String deviceId, String newName) async {
    setLoading(true);
    final success = await _deviceRepo.renameDevice(deviceId, newName);
    setLoading(false);

    if (!success) {
      setError("Failed to update name");
    }
    return success;
  }

  // 初始化mqtt
  Future<void> _initGlobalMqttAndSubscribe() async {
    if (_devices.isEmpty) return;

    if (locator<MqttManager>().isConnected) {
      debugPrint('⚡ MQTT 当前已是连接状态，跳过凭证获取，直接检查设备路由...');
      await _subscribeAllDevices();
      return;
    }

    // 未连接时，正常获取凭证
    final credResult = await locator<HttpClient>().post<Map<String, dynamic>>(ApiEndpoints.mqttCredentials);

    if (credResult.code != 0 && credResult.code != 200) {
      debugPrint('❌ 获取 MQTT 凭证失败: ${credResult.message}');
      return;
    }

    final mqttData = credResult.data!['mqtt'];
    if (mqttData == null) {
      debugPrint('❌ MQTT 凭证数据为空');
      return;
    }

    // 建立 MQTT 底层长连接
    final bool isConnected = await locator<MqttManager>().connect(
      endpoint: mqttData['endpoint'],
      port: int.tryParse(mqttData['port'].toString()) ?? 8883,
      username: mqttData['username'],
      password: mqttData['password'],
      clientId: mqttData['clientIdHint'],
      subscribeTopic: mqttData['subscribeTopic'],
      useTls: mqttData['tls'].toString() == 'true',
    );

    // 连上之后，打通云端路由
    if (isConnected) {
      debugPrint('MQTT连接成功');
      await _subscribeAllDevices();
    }
  }

  Future<void> _subscribeAllDevices() async {
    final subResult = await locator<HttpClient>().post(ApiEndpoints.mqttSubscribeSync);

    if (subResult.code == 0 || subResult.code == 200) {
      debugPrint('✅ 一键同步订阅所有设备成功');
    } else {
      debugPrint('⚠️ 一键同步订阅失败: ${subResult.message}');
    }
  }

  Future<bool> deleteDevice(String deviceId) async {
    setLoading(true);
    clearError();
    try {
      final homeList = await locator<HttpClient>().get(ApiEndpoints.homeList);
      if (homeList.data != null && homeList.data['items'] != null && homeList.data['items'].isNotEmpty) {
        final homeId = homeList.data['items'][0]['id'];
        final res = await locator<HttpClient>().delete(ApiEndpoints.deviceUnBind(homeId, deviceId));

        if (res.code == 0 || res.code == 200) {
          _devices.removeWhere((d) => d.deviceId == deviceId);
          notifyListeners();
          return true;
        } else {
          setError(res.message);
        }
      }
    } catch (e) {
      setError("删除设备失败，请稍后重试");
    } finally {
      setLoading(false);
    }
    return false;
  }
}
