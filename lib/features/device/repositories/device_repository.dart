import 'dart:async';
import 'dart:convert';
import 'package:fullxpet/locator.dart';
import 'package:flutter/material.dart';
import 'package:fullxpet/core/mqtt/mqtt_manager.dart';
import 'package:fullxpet/core/network/http_client.dart';
import 'package:fullxpet/core/network/api_endpoints.dart';
import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/features/device/models/device_dto.dart';
import 'package:fullxpet/features/device/models/device_thing_model.dart';

class DeviceRepository extends BaseProvider {
  final HttpClient _httpClient = locator<HttpClient>();
  final MqttManager _mqttManager = locator<MqttManager>();
  final Map<String, DeviceDto> _devicePool = {};
  StreamSubscription<Map<String, dynamic>>? _mqttSub;

  DeviceRepository() {
    _startListeningMqtt();
  }

  final StreamController<String> _deviceUpdateController = StreamController<String>.broadcast();

  Stream<String> get onDeviceUpdated => _deviceUpdateController.stream;

  //获取设备列表
  Future<List<DeviceDto>> getDeviceList() async {
    List<DeviceDto> devices = [];
    final result = await locator<HttpClient>().get<Map<String, dynamic>>(ApiEndpoints.devices);

    if (result.data != null) {
      final List<dynamic> listData = result.data!['items'] ?? [];
      for (var item in listData) {
        final json = item as Map<String, dynamic>;
        final deviceId = json['deviceId']?.toString() ?? '';
        if (deviceId.isEmpty) continue;

        updateBaseInfo(deviceId, name: json['nickname']?.toString(), isOnline: json['online'] ?? false);

        devices.add(getDevice(deviceId));
      }
    } else {
      setError(result.message);
    }
    return devices;
  }

  //修改设备名称
  Future<bool> renameDevice(String deviceId, String newName) async {
    try {
      final apiPath = ApiEndpoints.deviceName(deviceId);
      final result = await _httpClient.patch(apiPath, data: {"nickname": newName});
      if (result.code == 0 || result.code == 200) {
        updateBaseInfo(deviceId, name: newName);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Rename Device Error [$deviceId]: $e");
      return false;
    }
  }

  // 发送设备通用控制指令
  Future<bool> _sendDeviceCommand(String deviceId, List<Map<String, dynamic>> attributes) async {
    final apiPath = ApiEndpoints.deviceInvoke(deviceId);
    final payload = {"attributes": attributes};
    try {
      final result = await _httpClient.post(apiPath, data: payload);
      return result.code == 0 || result.code == 200;
    } catch (e) {
      debugPrint("Command Error [$deviceId]: $e");
      return false;
    }
  }

  // 设置设备工作模式
  Future<bool> setWorkMode(String deviceId, WorkMode mode) async {
    final attrs = <Map<String, dynamic>>[
      {"dpid": DeviceThingModel.deviceMode.dpid, "value": mode.value.toString()},
    ];
    if (mode == WorkMode.timer) {
      attrs.add({"dpid": DeviceThingModel.timerModeSchedule.dpid, "value": '["0","28800"]'});
    }
    return await _sendDeviceCommand(deviceId, attrs);
  }

  // 设置免打扰开关状态
  Future<bool> setDndStatus(String deviceId, bool isEnabled) async {
    return await _sendDeviceCommand(deviceId, [
      {"dpid": DeviceThingModel.notdisturbModeStatus.dpid, "value": isEnabled},
    ]);
  }

  // 设置童锁开关状态
  Future<bool> setChildLock(String deviceId, bool isEnabled) async {
    return await _sendDeviceCommand(deviceId, [
      {"dpid": DeviceThingModel.childLockSwitch.dpid, "value": isEnabled},
    ]);
  }

  // 执行单次设备操作 (清理/抚平)
  Future<bool> executeAction(String deviceId, ExecuteAction action) async {
    String? targetDpid;
    if (action == ExecuteAction.cleaning) {
      targetDpid = DeviceThingModel.cleanCatLitter.dpid;
    } else if (action == ExecuteAction.smoothing) {
      targetDpid = DeviceThingModel.flatCatLitter.dpid;
    }
    if (targetDpid == null) return false;
    return await _sendDeviceCommand(deviceId, [
      {"dpid": targetDpid, "value": true},
    ]);
  }

  // 设置自动模式延迟时间
  Future<bool> setAutoModeDelay(String deviceId, int delaySeconds) async {
    return await _sendDeviceCommand(deviceId, [
      {"dpid": DeviceThingModel.autoModeDelay.dpid, "value": delaySeconds.toString()},
    ]);
  }

  // 设置免打扰时间段
  Future<bool> setDndTimeRange(String deviceId, int startSeconds, int endSeconds) async {
    final dndJsonString = jsonEncode({"TimerStart": startSeconds.toString(), "TimerEnd": endSeconds.toString()});
    return await _sendDeviceCommand(deviceId, [
      {"dpid": DeviceThingModel.notdisturbModeSchedule.dpid, "value": dndJsonString},
    ]);
  }

  // 提交定时任务列表
  Future<bool> submitTimers(String deviceId, List<int> secondsArray) async {
    final timersJsonString = jsonEncode(secondsArray.map((e) => e.toString()).toList());
    return await _sendDeviceCommand(deviceId, [
      {"dpid": DeviceThingModel.timerModeSchedule.dpid, "value": timersJsonString},
    ]);
  }

  // 开始称重校准 (第一步)
  Future<bool> startCalibrationStep1(String deviceId) async {
    return await _sendDeviceCommand(deviceId, [
      {"dpid": DeviceThingModel.prepareCalibration.dpid, "value": true},
    ]);
  }

  // 提交校准重量 (第三步)
  Future<bool> submitCalibrationStep3(String deviceId, int weightGrams) async {
    return await _sendDeviceCommand(deviceId, [
      {"dpid": DeviceThingModel.calibrationWeight.dpid, "value": weightGrams},
      {"dpid": DeviceThingModel.calibration.dpid, "value": true},
    ]);
  }

  // 重置设备 Wi-Fi
  Future<bool> resetWifi(String deviceId) async {
    return await _sendDeviceCommand(deviceId, [
      {"dpid": DeviceThingModel.resetWlan.dpid, "value": true},
    ]);
  }

  // 从设备池获取设备
  DeviceDto getDevice(String deviceId) {
    if (!_devicePool.containsKey(deviceId)) {
      _devicePool[deviceId] = DeviceDto(deviceId: deviceId);
    }
    return _devicePool[deviceId]!;
  }

  // 获取设备列表
  Future<void> fetchDeviceList() async {
    try {
      final result = await _httpClient.get<Map<String, dynamic>>(ApiEndpoints.devices);
      if (result.data != null) {
        final List<dynamic> listData = result.data!['items'] ?? [];
        for (var item in listData) {
          final json = item as Map<String, dynamic>;
          final deviceId = json['deviceId']?.toString() ?? '';
          if (deviceId.isEmpty) continue;
          updateBaseInfo(deviceId, name: json['nickname']?.toString(), isOnline: json['online'] ?? false);
        }
      }
    } catch (e) {
      debugPrint("Fetch Device List Error: $e");
    }
  }

  // 获取设备信息
  Future<void> fetchDeviceProperties(String deviceId) async {
    try {
      final apiPath = ApiEndpoints.deviceProperties(deviceId);
      final result = await _httpClient.get<Map<String, dynamic>>(apiPath);
      if (result.data != null) {
        final data = result.data!;
        updateBaseInfo(deviceId, name: data['deviceName']?.toString(), isOnline: data['online'] ?? false);
        if (data.containsKey('attributes') && data['attributes'] is List) {
          updateDeviceAttributes(deviceId, data['attributes']);
        }
      }
    } catch (e) {
      debugPrint("Fetch Device Properties Error: $e");
    }
  }

  // 获取设备历史日志
  Future<void> fetchDeviceLogs(String deviceId, {bool isLoadMore = false}) async {
    final device = getDevice(deviceId);
    if (isLoadMore && !device.hasMoreLogs) return;
    if (!isLoadMore) {
      device.logs.clear();
      device.logNextPageToken = null;
      device.hasMoreLogs = true;
    }
    try {
      final now = DateTime.now();
      final todayStartUtc = DateTime(now.year, now.month, now.day).toUtc();
      final fromStr = "${todayStartUtc.toIso8601String().split('.').first}Z";
      final toStr = "${now.toUtc().toIso8601String().split('.').first}Z";
      final targetDpids = [DeviceThingModel.deviceExecute.dpid, DeviceThingModel.excretionTimeDay.dpid].join(',');
      final query = {"from": fromStr, "to": toStr, "dpid": targetDpids, "pageSize": "20", "sort": "desc"};
      if (device.logNextPageToken != null) {
        query["pageToken"] = device.logNextPageToken!;
      }
      final result = await _httpClient.get<Map<String, dynamic>>(ApiEndpoints.deviceLogs(deviceId), query: query);
      if (result.data != null) {
        final data = result.data!;
        final List<dynamic> items = data['items'] ?? [];
        for (var item in items) {
          final String tsStr = item['ts'] ?? '';
          final List<dynamic> values = item['values'] ?? [];
          if (tsStr.isEmpty || values.isEmpty) continue;
          final time = DateTime.parse(tsStr).toLocal();
          for (var valObj in values) {
            final dpid = valObj['dpid']?.toString();
            final value = valObj['value'];
            final content = _parseLogAction(dpid, value);
            if (content != null) {
              device.logs.add(DeviceLog(time: time, content: content));
            }
          }
        }
        device.logNextPageToken = data['nextPageToken']?.toString();
        device.hasMoreLogs = data['hasMore'] == true;
        _notifyDeviceChanged(deviceId);
      }
    } catch (e) {
      debugPrint("Fetch Device Logs Error: $e");
    }
  }

  // 初始化并监听 MQTT 消息
  void _startListeningMqtt() {
    _mqttSub = _mqttManager.messageStream.listen((data) {
      debugPrint('==== [Repository 监听到设备推送] ==== \n$data');
      final deviceId = data['deviceId']?.toString() ?? '';
      if (deviceId.isEmpty) return;
      final type = data['type']?.toString();
      if (type == 'attr_report') {
        if (data.containsKey('changedAttributes') && data['changedAttributes'] is Map) {
          final Map<String, dynamic> changedAttrs = Map<String, dynamic>.from(data['changedAttributes']);
          updateDeviceAttributesFromMap(deviceId, changedAttrs);
          _appendMqttLog(deviceId, changedAttrs, data['at']);
        } else if (data.containsKey('functionalAttributes') && data['functionalAttributes'] is Map) {
          final Map<String, dynamic> functionalAttrs = Map<String, dynamic>.from(data['functionalAttributes']);
          updateDeviceAttributesFromMap(deviceId, functionalAttrs);
          _appendMqttLog(deviceId, functionalAttrs, data['at']);
        }
      }
    });
  }

  // 追加 MQTT 实时上报日志
  void _appendMqttLog(String deviceId, Map<String, dynamic> changedAttrs, dynamic atTimestamp) {
    final device = getDevice(deviceId);
    bool hasNewLog = false;
    DateTime time;
    if (atTimestamp != null) {
      time = DateTime.fromMillisecondsSinceEpoch(int.parse(atTimestamp.toString())).toLocal();
    } else {
      time = DateTime.now();
    }
    changedAttrs.forEach((dpid, value) {
      final content = _parseLogAction(dpid, value);
      if (content != null) {
        device.logs.insert(0, DeviceLog(time: time, content: content));
        hasNewLog = true;
      }
    });
    if (hasNewLog) _notifyDeviceChanged(deviceId);
  }

  final Map<String, Object> modelys = {"1": "Clean", "2": "Smooth", "3": "加沙", "4": "清沙"};
  // 解析日志动作文案
  String? _parseLogAction(String? dpid, dynamic value) {
    if (dpid == DeviceThingModel.deviceExecute.dpid) {
      return modelys[value]?.toString();
    }
    if (dpid == DeviceThingModel.excretionTimeDay.dpid) {
      return "猫咪本次如厕: ${value.toString()}秒";
    }
    return null;
  }

  // 从 Map 结构更新设备属性
  void updateDeviceAttributesFromMap(String deviceId, Map<String, dynamic> attributes) {
    final device = getDevice(deviceId);
    device.updateAttributesFromMap(attributes);
    _notifyDeviceChanged(deviceId);
  }

  // 释放资源
  void dispose() {
    _mqttSub?.cancel();
    _deviceUpdateController.close();
  }

  // 更新设备基础信息 (名称/在线状态)
  void updateBaseInfo(String deviceId, {String? name, bool? isOnline}) {
    final device = getDevice(deviceId);
    bool hasChanged = false;
    if (name != null && device.deviceName != name) {
      device.deviceName = name;
      hasChanged = true;
    }
    if (isOnline != null && device.isOnline != isOnline) {
      device.isOnline = isOnline;
      hasChanged = true;
    }
    if (hasChanged) {
      _notifyDeviceChanged(deviceId);
    }
  }

  // 批量更新设备属性列表
  void updateDeviceAttributes(String deviceId, List<dynamic> attributes) {
    final device = getDevice(deviceId);
    device.updateAttributes(attributes);
    _notifyDeviceChanged(deviceId);
  }

  // 通知 UI 层设备状态变更
  void _notifyDeviceChanged(String deviceId) {
    _deviceUpdateController.add(deviceId);
  }
}
