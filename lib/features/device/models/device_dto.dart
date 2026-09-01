import 'dart:convert';
import 'package:fullxpet/core/utils/device_batch_helper.dart';
import 'device_thing_model.dart';
import 'package:fullxpet/core/utils/time_utils.dart';

//设备日志
class DeviceLog {
  final DateTime time;
  final String content;
  final bool isAction;
  DeviceLog({required this.time, required this.content, required this.isAction});
}

//设备属性
class DeviceDto {
  final String deviceId;
  String deviceName;
  bool isOnline;
  String get displayId => DeviceBatchHelper().getDisplayBatchNo(deviceId);
  final Map<String, dynamic> _attributes = {};
  final List<DeviceLog> logs = [];

  String? logNextPageToken;
  bool hasMoreLogs = true;

  int savedCalibrationWeight = 5000;
  String timeZoneId = 'Asia/Shanghai';
  String timeZoneOffset = 'UTC+08:00';
  bool hasNewFirmware = false;
  String newFirmwareVersion = '';
  String pendingOtaRecordId = '';
  bool isOtaUpdating = false;

  DeviceDto({
    required this.deviceId,
    this.deviceName = 'FULLXPET',
    this.isOnline = false,
    Map<String, dynamic>? attributes,
  }) {
    if (attributes != null) {
      _attributes.addAll(attributes);
    }
  }

  // 物模型属性与计算属性
  ExecuteAction get executeAction {
    final val = _attributes[DeviceThingModel.deviceExecute.dpid];
    if (val?.toString() == '5') {
      return ExecuteAction.idle;
    }
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

  bool get isPlasmaEnabled {
    final val = _attributes[DeviceThingModel.palsmaState.dpid];
    return val == true || val?.toString() == 'true';
  }

  bool get isDndEnabled {
    final val = _attributes[DeviceThingModel.notdisturbModeStatus.dpid];
    return val == true || val?.toString() == 'true';
  }

  String get wifiSsid => _attributes[DeviceThingModel.deviceSsid.dpid]?.toString() ?? '';
  String get wifiRssi => "${_attributes[DeviceThingModel.deviceRssi.dpid] ?? 0}dBm";
  String get wifiIp => _attributes[DeviceThingModel.deviceIp.dpid]?.toString() ?? '0.0.0.0';
  String get wifiMac => _attributes[DeviceThingModel.deviceMac.dpid]?.toString() ?? '00:00:00:00:00:00';
  String get firmwareVersion => _attributes[DeviceThingModel.deviceVersion.dpid]?.toString() ?? '';

  String get todayTimes => _attributes[DeviceThingModel.excretionTimesDay.dpid]?.toString() ?? '0';
  String get averageSeconds => _attributes[DeviceThingModel.excretionTimeDay.dpid]?.toString() ?? '0';

  int get autoModeDelaySeconds {
    final val = _attributes[DeviceThingModel.autoModeDelay.dpid];
    return int.tryParse(val?.toString() ?? '') ?? 60;
  }

  int get autoModeIndex {
    int mins = autoModeDelaySeconds ~/ 60;
    int idx = mins - 1;
    return (idx >= 0 && idx <= 4) ? idx : 0;
  }

  List<String> get timerList {
    final val = _attributes[DeviceThingModel.timerModeSchedule.dpid];
    if (val == null) return [];
    try {
      final List<dynamic> tList = jsonDecode(val.toString());
      List<String> result = [];
      for (var t in tList) {
        int seconds = int.parse(t.toString());
        result.add(TimeUtils.secondsToTime(seconds));
      }
      result.sort();
      return result;
    } catch (_) {
      return [];
    }
  }

  Map<String, String> get dndTimeRange {
    final val = _attributes[DeviceThingModel.notdisturbModeSchedule.dpid];
    String start = '22:00';
    String end = '06:00';
    if (val != null) {
      try {
        final Map<String, dynamic> dndMap = jsonDecode(val.toString());
        if (dndMap.containsKey('TimerStart')) {
          start = TimeUtils.secondsToTime(int.parse(dndMap['TimerStart'].toString()));
        }
        if (dndMap.containsKey('TimerEnd')) {
          end = TimeUtils.secondsToTime(int.parse(dndMap['TimerEnd'].toString()));
        }
      } catch (_) {}
    }
    return {'start': start, 'end': end};
  }

  bool get isOperating {
    final dpid8 = _attributes[DeviceThingModel.deviceStatus.dpid]?.toString();
    final dpid9 = _attributes[DeviceThingModel.deviceExecute.dpid]?.toString();
    if (dpid9 == '5') return false;
    if (dpid8 != '0' || dpid9 != '0') return true;
    return false;
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

  // 等离子工作时间排期 (DP 32: {"runTime":"3600","outTime":"1800"})
  Map<String, int> get plasmaSchedule {
    final val = _attributes[DeviceThingModel.plasmaSchedule.dpid];
    if (val == null || val.toString().isEmpty) {
      return {'runTime': 3600, 'outTime': 1800}; // 默认配置
    }
    try {
      final decoded = jsonDecode(val.toString());
      if (decoded is Map) {
        return {
          'runTime': int.tryParse(decoded['runTime']?.toString() ?? '0') ?? 0,
          'outTime': int.tryParse(decoded['outTime']?.toString() ?? '0') ?? 0,
        };
      }
    } catch (_) {}
    return {'runTime': 3600, 'outTime': 1800};
  }

  // 是否为常开模式 (runTime == 0 && outTime == 0)
  bool get isPlasmaAlwaysOn {
    final sched = plasmaSchedule;
    return sched['runTime'] == 0 && sched['outTime'] == 0;
  }
}
