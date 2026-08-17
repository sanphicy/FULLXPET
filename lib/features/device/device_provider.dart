import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/core/mqtt/mqtt_manager.dart';
import 'package:fullxpet/core/network/api_endpoints.dart';
import 'package:fullxpet/core/network/http_client.dart';
import 'package:fullxpet/features/device/models/device_dto.dart';
import 'package:fullxpet/features/device/repositories/device_repository.dart';
import 'package:fullxpet/locator.dart';

class DeviceProvider extends BaseProvider {
  final DeviceRepository _deviceRepo = locator<DeviceRepository>();
  List<DeviceDto> _devices = [];
  List<DeviceDto> get devices => _devices;
  StreamSubscription<String>? _repoSubscription;

  DeviceProvider() {
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

  Future<void> fetchDevices() async {
    setLoading(true);
    clearError();
    try {
      final result = await _deviceRepo.getDeviceList();
      if (result.data != null) {
        _devices = result.data!;
        _initGlobalMqttAndSubscribe();
      } else {
        setError(result.message);
      }
      notifyListeners();
    } catch (_) {
      setError("网络连接失败，请检查网络设置");
    } finally {
      if (isLoading) setLoading(false);
    }
  }

  Future<bool> renameDevice(String deviceId, String newName) async {
    setLoading(true);
    final success = await _deviceRepo.renameDevice(deviceId, newName);
    setLoading(false);
    if (!success) {
      setError("Failed to update name");
    }
    return success;
  }

  Future<void> _initGlobalMqttAndSubscribe() async {
    if (_devices.isEmpty) return;

    if (locator<MqttManager>().isConnected) {
      await _subscribeAllDevices();
      return;
    }

    final credResult = await locator<HttpClient>().post<Map<String, dynamic>>(ApiEndpoints.mqttCredentials);
    if (credResult.code != 0 && credResult.code != 200) {
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

  Future<void> _subscribeAllDevices() async {
    final subResult = await locator<HttpClient>().post(ApiEndpoints.mqttSubscribeSync);
    if (subResult.code == 0 || subResult.code == 200) {
      debugPrint('一键同步订阅所有设备成功');
    } else {
      debugPrint('一键同步订阅失败: ${subResult.message}');
    }
  }

  Future<bool> deleteDevice(String deviceId) async {
    setLoading(true);
    clearError();
    try {
      final success = await _deviceRepo.deleteDevice(deviceId);
      if (success) {
        _devices.removeWhere((d) => d.deviceId == deviceId);
        notifyListeners();
        return true;
      } else {
        setError("删除设备失败，请稍后重试");
      }
    } catch (_) {
      setError("删除设备失败，请稍后重试");
    } finally {
      setLoading(false);
    }
    return false;
  }
}
