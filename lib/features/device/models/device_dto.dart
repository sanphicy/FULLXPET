import 'dart:convert';
import 'device_thing_model.dart';

class DeviceLog {
  final DateTime time;
  final String content;

  DeviceLog({required this.time, required this.content});
}

class DeviceDto {
  final String deviceId;
  String deviceName;
  bool isOnline;

  final Map<String, dynamic> _attributes = {};
  final List<DeviceLog> logs = [];

  String? logNextPageToken;
  bool hasMoreLogs = true;

  DeviceDto({
    required this.deviceId,
    this.deviceName = 'PETLUX-V3',
    this.isOnline = false,
    Map<String, dynamic>? attributes,
  }) {
    if (attributes != null) {
      _attributes.addAll(attributes);
    }
  }

  ExecuteAction get executeAction {
    final val = _attributes[DeviceThingModel.deviceExecute.dpid];
    // ========== PATCH START ==========
    // 临时补丁解决设备复位完成后不上报状态问题
    if (val?.toString() == '5') {
      return ExecuteAction.idle;
    }
    // ========== PATCH END ==========
    return ExecuteAction.fromValue(int.tryParse(val?.toString() ?? '') ?? 0);
  }

  bool get isDeviceIdle => executeAction == ExecuteAction.idle;

  WorkMode get workMode {
    final val = _attributes[DeviceThingModel.deviceMode.dpid];
    return WorkMode.fromValue(int.tryParse(val?.toString() ?? '') ?? 0);
  }

  bool get isChildLockEnabled {
    final val = _attributes[DeviceThingModel.childLockSwitch.dpid];
    return val == true || val?.toString() == 'true';
  }

  bool get isDndEnabled {
    final val = _attributes[DeviceThingModel.notdisturbModeStatus.dpid];
    return val == true || val?.toString() == 'true';
  }

  String get wifiSsid => _attributes[DeviceThingModel.deviceSsid.dpid]?.toString() ?? "";
  String get wifiRssi => "${_attributes[DeviceThingModel.deviceRssi.dpid] ?? 0}dBm";
  String get wifiIp => _attributes[DeviceThingModel.deviceIp.dpid]?.toString() ?? "0.0.0.0";
  String get wifiMac => _attributes[DeviceThingModel.deviceMac.dpid]?.toString() ?? "00:00:00:00:00:00";
  String get firmwareVersion => _attributes[DeviceThingModel.deviceVersion.dpid]?.toString() ?? "";

  String get todayTimes => _attributes[DeviceThingModel.excretionTimesDay.dpid]?.toString() ?? "0";
  String get averageSeconds => _attributes[DeviceThingModel.excretionTimeDay.dpid]?.toString() ?? "0";

  int get autoModeDelaySeconds {
    final val = _attributes[DeviceThingModel.autoModeDelay.dpid];
    return int.tryParse(val?.toString() ?? '') ?? 60;
  }

  List<String> get timerList {
    final val = _attributes[DeviceThingModel.timerModeSchedule.dpid];
    if (val == null) return [];
    try {
      final List<dynamic> tList = jsonDecode(val.toString());
      List<String> result = [];
      for (var t in tList) {
        int seconds = int.parse(t.toString());
        result.add(_secondsToTime(seconds));
      }
      result.sort();
      return result;
    } catch (e) {
      return [];
    }
  }

  Map<String, String> get dndTimeRange {
    final val = _attributes[DeviceThingModel.notdisturbModeSchedule.dpid];
    String start = "22:00";
    String end = "06:00";
    if (val != null) {
      try {
        final Map<String, dynamic> dndMap = jsonDecode(val.toString());
        if (dndMap.containsKey('TimerStart')) {
          start = _secondsToTime(int.parse(dndMap['TimerStart'].toString()));
        }
        if (dndMap.containsKey('TimerEnd')) {
          end = _secondsToTime(int.parse(dndMap['TimerEnd'].toString()));
        }
      } catch (e) {
        // JSON Parse Error
      }
    }
    return {"start": start, "end": end};
  }

  void updateAttributes(List<dynamic> newAttributes) {
    for (var attr in newAttributes) {
      if (attr is Map<String, dynamic>) {
        final dpid = attr['dpid']?.toString();
        final value = attr['value'];
        if (dpid != null && value != null) {
          _attributes[dpid] = value;
        }
      }
    }
  }

  void updateAttributesFromMap(Map<String, dynamic> changedAttributes) {
    changedAttributes.forEach((dpid, value) {
      _attributes[dpid.toString()] = value;
    });
  }

  bool get isOperating {
    final dpid8 = _attributes[DeviceThingModel.deviceStatus.dpid]?.toString();
    final dpid9 = _attributes[DeviceThingModel.deviceExecute.dpid]?.toString();
    // ========== PATCH START ==========
    // 临时补丁解决设备复位完成后不上报状态问题
    if (dpid9 == '5') {
      return false;
    }
    // ========== PATCH END ==========
    if (dpid8 != '0' || dpid9 != '0') return true;
    return false;
  }

  String _secondsToTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
