import 'dart:convert';
import 'package:fullxpet/core/utils/time_utils.dart';
import 'package:fullxpet/features/device/models/device_dto.dart';
import 'package:fullxpet/features/device/models/device_thing_model.dart';
import 'package:fullxpet/features/device/models/device_log.dart';

class LitterBoxDevice {
  final DeviceDto dto;

  final List<DeviceLog> logs = [];
  String? logNextPageToken;
  bool hasMoreLogs = true;
  int savedCalibrationWeight = 5000;
  String timeZoneId = 'Asia/Shanghai';
  String timeZoneOffset = 'UTC+08:00';

  LitterBoxDevice({required this.dto});

  Map<String, dynamic> get _attrs => dto.attributes;

  // --- 猫砂盆专属 DP 属性解析 ---
  bool get hasPlasma {
    final modelCode = dto.product?.modelCode.toUpperCase() ?? '';
    return !modelCode.contains('V4');
  }

  ExecuteAction get executeAction {
    if (!dto.isOnline) return ExecuteAction.idle;
    final val = _attrs[DeviceThingModel.deviceExecute.dpid];
    if (val?.toString() == '5') return ExecuteAction.idle;
    return ExecuteAction.fromValue(int.tryParse(val?.toString() ?? '') ?? 0);
  }

  bool get isDeviceIdle => executeAction == ExecuteAction.idle;

  WorkMode get workMode {
    final val = _attrs[DeviceThingModel.deviceMode.dpid];
    return WorkMode.fromValue(int.tryParse(val?.toString() ?? '') ?? 0);
  }

  bool get isChildLockEnabled {
    final val = _attrs[DeviceThingModel.childLockSwitch.dpid];
    return val == true || val?.toString() == 'true';
  }

  bool get isPlasmaEnabled {
    final val = _attrs[DeviceThingModel.palsmaState.dpid];
    return val == true || val?.toString() == 'true';
  }

  bool get isDndEnabled {
    final val = _attrs[DeviceThingModel.notdisturbModeStatus.dpid];
    return val == true || val?.toString() == 'true';
  }

  String get wifiSsid => (dto.hardwareInfo?.ssid.isNotEmpty == true)
      ? dto.hardwareInfo!.ssid
      : (_attrs[DeviceThingModel.deviceSsid.dpid]?.toString() ?? '');

  String get wifiRssi {
    final raw = (dto.hardwareInfo?.rssi.isNotEmpty == true)
        ? dto.hardwareInfo!.rssi
        : (_attrs[DeviceThingModel.deviceRssi.dpid]?.toString() ?? '0');
    return raw.endsWith('dBm') ? raw : '${raw}dBm';
  }

  String get wifiIp => _attrs[DeviceThingModel.deviceIp.dpid]?.toString() ?? '0.0.0.0';

  String get wifiMac => _attrs[DeviceThingModel.deviceMac.dpid]?.toString() ?? '00:00:00:00:00:00';

  String get firmwareVersion => (dto.hardwareInfo?.mcuVersion.isNotEmpty == true)
      ? dto.hardwareInfo!.mcuVersion
      : (_attrs[DeviceThingModel.deviceVersion.dpid]?.toString() ?? '');

  String get todayTimes => _attrs[DeviceThingModel.excretionTimesDay.dpid]?.toString() ?? '0';

  String get averageSeconds => _attrs[DeviceThingModel.excretionTimeDay.dpid]?.toString() ?? '0';

  int get autoModeDelaySeconds {
    final val = _attrs[DeviceThingModel.autoModeDelay.dpid];
    return int.tryParse(val?.toString() ?? '') ?? 60;
  }

  int get autoModeIndex {
    final idx = (autoModeDelaySeconds ~/ 60) - 1;
    return (idx >= 0 && idx <= 4) ? idx : 0;
  }

  bool get isOperating {
    if (!dto.isOnline) return false;
    final dpid8 = _attrs[DeviceThingModel.deviceStatus.dpid]?.toString() ?? '0';
    final dpid9 = _attrs[DeviceThingModel.deviceExecute.dpid]?.toString() ?? '0';
    if (dpid9 == '5') return false;
    return dpid8 != '0' || dpid9 != '0';
  }

  List<String> get timerList {
    final val = _attrs[DeviceThingModel.timerModeSchedule.dpid];
    if (val == null) return [];
    try {
      final List<dynamic> tList = val is List ? val : jsonDecode(val.toString());
      final result = tList.map((t) => TimeUtils.secondsToTime(int.parse(t.toString()))).toList();
      result.sort();
      return result;
    } catch (_) {
      return [];
    }
  }

  Map<String, String> get dndTimeRange {
    final val = _attrs[DeviceThingModel.notdisturbModeSchedule.dpid];
    String start = '22:00';
    String end = '06:00';
    if (val != null) {
      try {
        final Map<String, dynamic> dndMap = val is Map<String, dynamic> ? val : jsonDecode(val.toString());
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

  Map<String, int> get plasmaSchedule {
    final val = _attrs[DeviceThingModel.plasmaSchedule.dpid];
    if (val == null || val.toString().isEmpty) {
      return {'runTime': 3600, 'outTime': 1800};
    }
    try {
      final decoded = val is Map ? val : jsonDecode(val.toString());
      if (decoded is Map) {
        return {
          'runTime': int.tryParse(decoded['runTime']?.toString() ?? '0') ?? 0,
          'outTime': int.tryParse(decoded['outTime']?.toString() ?? '0') ?? 0,
        };
      }
    } catch (_) {}
    return {'runTime': 3600, 'outTime': 1800};
  }

  bool get isPlasmaAlwaysOn {
    final sched = plasmaSchedule;
    return sched['runTime'] == 0 && sched['outTime'] == 0;
  }
}
