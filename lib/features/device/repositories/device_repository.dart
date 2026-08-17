import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:fullxpet/core/mqtt/mqtt_manager.dart';
import 'package:fullxpet/core/network/api_endpoints.dart';
import 'package:fullxpet/core/network/http_client.dart';
import 'package:fullxpet/core/result/result_model.dart';
import 'package:fullxpet/features/device/models/device_dto.dart';
import 'package:fullxpet/features/device/models/device_thing_model.dart';
import 'package:fullxpet/locator.dart';

class DeviceRepository {
  final HttpClient _httpClient = locator<HttpClient>();
  final MqttManager _mqttManager = locator<MqttManager>();
  final Map<String, DeviceDto> _devicePool = {};
  StreamSubscription<Map<String, dynamic>>? _mqttSub;

  final StreamController<String> _deviceUpdateController = StreamController<String>.broadcast();
  Stream<String> get onDeviceUpdated => _deviceUpdateController.stream;

  DeviceRepository() {
    _startListeningMqtt();
  }

  void clearPool() {
    _devicePool.clear();
  }

  DeviceDto getDevice(String deviceId) {
    if (!_devicePool.containsKey(deviceId)) {
      _devicePool[deviceId] = DeviceDto(deviceId: deviceId);
    }
    return _devicePool[deviceId]!;
  }

  Future<ResultEntity<List<DeviceDto>>> getDeviceList() async {
    final result = await _httpClient.get<Map<String, dynamic>>(ApiEndpoints.devices);
    if (result.data != null && (result.code == 0 || result.code == 200)) {
      final List<dynamic> listData = result.data!['items'] ?? [];
      List<DeviceDto> devices = [];
      for (var item in listData) {
        final json = item as Map<String, dynamic>;
        final deviceId = json['deviceId']?.toString() ?? '';
        if (deviceId.isEmpty) continue;

        updateBaseInfo(deviceId, name: json['nickname']?.toString(), isOnline: json['online'] ?? false);
        devices.add(getDevice(deviceId));
      }
      return ResultEntity.success(devices);
    }
    return ResultEntity.error(result.message);
  }

  Future<bool> renameDevice(String deviceId, String newName) async {
    try {
      final result = await _httpClient.patch(ApiEndpoints.deviceName(deviceId), data: {'nickname': newName});
      if (result.code == 0 || result.code == 200) {
        updateBaseInfo(deviceId, name: newName);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Rename Device Error [$deviceId]: $e');
      return false;
    }
  }

  Future<bool> deleteDevice(String deviceId) async {
    try {
      final homeList = await _httpClient.get<Map<String, dynamic>>(ApiEndpoints.homeList);
      if (homeList.data != null && homeList.data!['items'] != null && (homeList.data!['items'] as List).isNotEmpty) {
        final homeId = homeList.data!['items'][0]['id']?.toString() ?? '';
        final res = await _httpClient.delete(ApiEndpoints.deviceUnBind(homeId, deviceId));
        if (res.code == 0 || res.code == 200) {
          _devicePool.remove(deviceId);
          return true;
        }
      }
    } catch (e) {
      debugPrint('Delete Device Error [$deviceId]: $e');
    }
    return false;
  }

  Future<bool> sendDeviceCommand(String deviceId, List<Map<String, dynamic>> attributes) async {
    try {
      final result = await _httpClient.post(ApiEndpoints.deviceInvoke(deviceId), data: {'attributes': attributes});
      return result.code == 0 || result.code == 200;
    } catch (e) {
      debugPrint('Command Error [$deviceId]: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> checkPendingFirmware(String deviceId) async {
    try {
      final res = await _httpClient.get<dynamic>(ApiEndpoints.checkFirmware(deviceId));
      if ((res.code == 0 || res.code == 200) && res.data != null) {
        final rawData = res.data;
        if (rawData is List && rawData.isNotEmpty) {
          return Map<String, dynamic>.from(rawData.first as Map);
        } else if (rawData is Map<String, dynamic>) {
          return rawData;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<bool> dispatchFirmwareUpgrade(String deviceId, String recordId) async {
    try {
      final result = await _httpClient.post<Map<String, dynamic>>(ApiEndpoints.upgradeFirmware(deviceId, recordId));
      return result.code == 0 || result.code == 200;
    } catch (e) {
      debugPrint('Dispatch Firmware Upgrade Error [$deviceId]: $e');
      return false;
    }
  }

  Future<void> fetchDeviceProperties(String deviceId) async {
    try {
      final result = await _httpClient.get<Map<String, dynamic>>(ApiEndpoints.deviceProperties(deviceId));
      if (result.data != null) {
        final data = result.data!;
        updateBaseInfo(deviceId, name: data['deviceName']?.toString(), isOnline: data['online'] ?? false);
        if (data.containsKey('attributes') && data['attributes'] is List) {
          updateDeviceAttributes(deviceId, data['attributes']);
        }
      }
    } catch (e) {
      debugPrint('Fetch Device Properties Error: $e');
    }
  }

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
      final query = {'from': fromStr, 'to': toStr, 'dpid': targetDpids, 'pageSize': '20', 'sort': 'desc'};
      if (device.logNextPageToken != null) {
        query['pageToken'] = device.logNextPageToken!;
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
      debugPrint('Fetch Device Logs Error: $e');
    }
  }

  void _startListeningMqtt() {
    _mqttSub = _mqttManager.messageStream.listen((data) {
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

  String? _parseLogAction(String? dpid, dynamic value) {
    if (dpid == DeviceThingModel.deviceExecute.dpid) {
      final valStr = value.toString();
      const actionMap = {'1': 'Clean', '2': 'Smooth', '3': 'Add Litter', '4': 'Empty Litter'};
      return actionMap[valStr];
    }
    if (dpid == DeviceThingModel.excretionTimeDay.dpid) {
      return value.toString();
    }
    return null;
  }

  void updateDeviceAttributesFromMap(String deviceId, Map<String, dynamic> attributes) {
    final device = getDevice(deviceId);
    device.updateAttributesFromMap(attributes);
    _notifyDeviceChanged(deviceId);
  }

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

  void updateDeviceAttributes(String deviceId, List<dynamic> attributes) {
    final device = getDevice(deviceId);
    device.updateAttributes(attributes);
    _notifyDeviceChanged(deviceId);
  }

  void _notifyDeviceChanged(String deviceId) {
    _deviceUpdateController.add(deviceId);
  }

  void dispose() {
    _mqttSub?.cancel();
    _deviceUpdateController.close();
  }
}
