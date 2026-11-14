import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/core/services/nav_service.dart';
import 'package:fullxpet/core/utils/device_batch_helper.dart';
import 'package:fullxpet/core/utils/time_utils.dart';
import 'package:fullxpet/features/device/models/device_hardware_info.dart';
import 'package:fullxpet/features/device/models/device_item_dto.dart';
import 'package:fullxpet/features/device/models/device_log.dart';
import 'package:fullxpet/features/device/models/product_dto.dart';
import 'package:fullxpet/features/device/products/litter_box/v3/models/device_thing_model.dart';
import 'package:fullxpet/features/device/repositories/device_repository.dart';
import 'package:fullxpet/locator.dart';

typedef DeviceLogList = List<DeviceLog>;
typedef StringList = List<String>;
typedef IntMap = Map<String, int>;
typedef StringMap = Map<String, String>;

class LitterBoxViewModel extends BaseProvider with WidgetsBindingObserver {
  final DeviceRepository _deviceRepo = locator.get();

  String _deviceId = '';
  String get deviceId => _deviceId;

  final DpidValueMap _optimisticOverrides = {};
  final DeviceLogList _logs = [];
  DeviceLogList get logs => List.unmodifiable(_logs);

  bool _hasNewFirmware = false;
  String _newFirmwareVersion = '';
  String _pendingOtaRecordId = '';
  bool _isOtaUpdating = false;
  Timer? _otaPollingTimer;

  int _savedCalibrationWeight = 5000;
  String _currentTimeZoneId = 'Asia/Shanghai';
  String _currentTimeZoneOffset = 'UTC+08:00';

  bool get hasNewFirmware => _hasNewFirmware;
  String get newFirmwareVersion => _newFirmwareVersion;
  bool get isOtaUpdating => _isOtaUpdating;
  int get savedCalibrationWeight => _savedCalibrationWeight;
  String get currentTimeZoneId => _currentTimeZoneId;
  String get currentTimeZoneOffset => _currentTimeZoneOffset;
  bool get isNetworkGood => true;

  final StringList autoModeOptions = const ['1', '2', '3', '4', '5'];

  StreamSubscription? _repoSub;

  LitterBoxViewModel() {
    _repoSub = _deviceRepo.onDeviceUpdated.listen((updatedId) {
      if (_deviceId.isNotEmpty && (updatedId == _deviceId || updatedId == 'ALL')) {
        notifyListeners();
      }
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    stopOtaPolling();
    WidgetsBinding.instance.removeObserver(this);
    _repoSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _deviceId.isNotEmpty) {
      _deviceRepo.fetchDeviceProperties(_deviceId);
    }
  }

  S? get _s {
    final BuildContext? ctx = NavService.rootNavigatorKey.currentContext;
    return ctx != null ? S.of(ctx) : null;
  }

  // ================= 1. 从底表 1、底表 2、硬件表读取设备信息 =================

  DeviceItemDto? get basicInfo => _deviceRepo.getDeviceBasic(_deviceId);

  ProductDto? get productInfo {
    final pid = basicInfo?.productId ?? '';
    return _deviceRepo.getProduct(pid);
  }

  DeviceHardwareInfo get hardwareInfo => _deviceRepo.getDeviceHardwareInfo(_deviceId);

  String get deviceName => basicInfo?.nickname.isNotEmpty == true ? basicInfo!.nickname : 'FULLXPET';
  String get productName => productInfo?.name ?? '';
  String get displayId => DeviceBatchHelper().getDisplayBatchNo(_deviceId);
  bool get isOnline => basicInfo?.online ?? false;

  String get imageUrl {
    final icon = basicInfo?.iconUrl ?? '';
    if (icon.isNotEmpty) return icon;
    return productInfo?.thumbnailUrl ?? '';
  }

  bool get hasCameraStream => basicInfo?.advancedFeatures.ipcStream ?? false;

  String get firmwareVersion {
    if (hardwareInfo.mcuVersion.isNotEmpty) return hardwareInfo.mcuVersion;
    if (hardwareInfo.wifiVersion.isNotEmpty) return hardwareInfo.wifiVersion;
    return _getDpid(DeviceThingModel.deviceVersion)?.toString() ?? '';
  }

  String get wifiSsid {
    if (hardwareInfo.ssid.isNotEmpty) return hardwareInfo.ssid;
    return _getDpid(DeviceThingModel.deviceSsid)?.toString() ?? '';
  }

  String get wifiRssi {
    final dpVal = _getDpid(DeviceThingModel.deviceRssi)?.toString() ?? '';
    if (dpVal.isNotEmpty && dpVal != '0') {
      return dpVal.endsWith('dBm') ? dpVal : '${dpVal}dBm';
    }
    if (hardwareInfo.rssi.isNotEmpty) {
      final r = hardwareInfo.rssi;
      return r.endsWith('dBm') ? r : '${r}dBm';
    }
    return '0dBm';
  }

  String get wifiIp => _getDpid(DeviceThingModel.deviceIp)?.toString() ?? '-';
  String get wifiMac => _getDpid(DeviceThingModel.deviceMac)?.toString() ?? '-';

  // ================= 2. 从底表 3 读取实时物模型属性 =================

  dynamic _getDpid(DeviceThingModel model) {
    if (_optimisticOverrides.containsKey(model.dpid)) {
      return _optimisticOverrides[model.dpid];
    }
    return _deviceRepo.getDpidValue(_deviceId, model.dpid);
  }

  int get todayTimes => int.tryParse(_getDpid(DeviceThingModel.excretionTimesDay)?.toString() ?? '0') ?? 0;
  int get averageSeconds => int.tryParse(_getDpid(DeviceThingModel.excretionTimeDay)?.toString() ?? '0') ?? 0;

  int get litterWeightGrams => int.tryParse(_getDpid(DeviceThingModel.litterWeight)?.toString() ?? '0') ?? 0;
  double get litterPercent => (litterWeightGrams / 4500.0).clamp(0.0, 1.0);

  int get shitWeightGrams => int.tryParse(_getDpid(DeviceThingModel.shitWeight)?.toString() ?? '0') ?? 0;
  double get shitPercent => (shitWeightGrams / 2000.0).clamp(0.0, 1.0);
  bool get isShitBinNearlyFull => shitWeightGrams >= 1600;

  ExecuteAction get currentAction {
    if (!isOnline) return ExecuteAction.idle;
    final val = _getDpid(DeviceThingModel.deviceExecute)?.toString() ?? '0';
    if (val == '5') return ExecuteAction.idle;
    return ExecuteAction.fromValue(int.tryParse(val) ?? 0);
  }

  bool get isOperating {
    if (!isOnline) return false;
    final dpid8 = _getDpid(DeviceThingModel.deviceStatus)?.toString() ?? '0';
    final dpid9 = _getDpid(DeviceThingModel.deviceExecute)?.toString() ?? '0';
    if (dpid9 == '5') return false;
    return dpid8 != '0' || dpid9 != '0';
  }

  WorkMode get workMode {
    final val = _getDpid(DeviceThingModel.deviceMode);
    return WorkMode.fromValue(int.tryParse(val?.toString() ?? '0') ?? 0);
  }

  bool get isDndEnabled {
    final val = _getDpid(DeviceThingModel.notdisturbModeStatus);
    return val == true || val?.toString() == 'true';
  }

  bool get isChildLockEnabled {
    final val = _getDpid(DeviceThingModel.childLockSwitch);
    return val == true || val?.toString() == 'true';
  }

  bool get isPlasmaEnabled {
    final val = _getDpid(DeviceThingModel.palsmaState);
    return val == true || val?.toString() == 'true';
  }

  int get autoDelayMinutes {
    final sec = int.tryParse(_getDpid(DeviceThingModel.autoModeDelay)?.toString() ?? '60') ?? 60;
    return (sec ~/ 60).clamp(1, 30);
  }

  int get autoModeIndex {
    final idx = autoDelayMinutes - 1;
    return (idx >= 0 && idx < autoModeOptions.length) ? idx : 0;
  }

  StringMap get dndTimeRange {
    final val = _getDpid(DeviceThingModel.notdisturbModeSchedule);
    String start = '22:00';
    String end = '06:00';
    if (val != null) {
      try {
        final Map map = jsonDecode(val.toString()) as Map;
        if (map.containsKey('TimerStart')) {
          start = TimeUtils.secondsToTime(int.parse(map['TimerStart'].toString()));
        }
        if (map.containsKey('TimerEnd')) {
          end = TimeUtils.secondsToTime(int.parse(map['TimerEnd'].toString()));
        }
      } catch (_) {}
    }
    return {'start': start, 'end': end};
  }

  String get dndRangeText => '${dndTimeRange['start']} -${dndTimeRange['end']}';

  IntMap get plasmaSchedule {
    final val = _getDpid(DeviceThingModel.plasmaSchedule);
    if (val != null && val.toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(val.toString());
        if (decoded is Map) {
          return {
            'runTime': int.tryParse(decoded['runTime']?.toString() ?? '0') ?? 0,
            'outTime': int.tryParse(decoded['outTime']?.toString() ?? '0') ?? 0,
          };
        }
      } catch (_) {}
    }
    return {'runTime': 3600, 'outTime': 1800};
  }

  bool get isPlasmaAlwaysOn {
    final sched = plasmaSchedule;
    return sched['runTime'] == 0 && sched['outTime'] == 0;
  }

  StringList get timerList {
    final val = _getDpid(DeviceThingModel.timerModeSchedule);
    if (val == null) return [];
    try {
      final List tList = jsonDecode(val.toString()) as List;
      final StringList result = [];
      for (final t in tList) {
        final int seconds = int.parse(t.toString());
        result.add(TimeUtils.secondsToTime(seconds));
      }
      result.sort();
      return result;
    } catch (_) {
      return [];
    }
  }

  String get modeSubParamText {
    if (isDndEnabled) return '勿扰时段: $dndRangeText';
    switch (workMode) {
      case WorkMode.auto:
        return '自动延迟: $autoDelayMinutes分钟';
      case WorkMode.timer:
        return '定时清理: 已设${timerList.length}组';
      case WorkMode.manual:
        return '仅手动触发清理';
    }
  }

  // ================= 3. 初始化加载与指令下发 =================

  Future<void> initDevice(String id) async {
    _deviceId = id;
    try {
      final prefs = await SharedPreferences.getInstance();
      _savedCalibrationWeight = prefs.getInt('calibration_weight_$id') ?? 5000;
      _currentTimeZoneId = await FlutterTimezone.getLocalTimezone();
      _currentTimeZoneOffset = TimeUtils.calculateOffsetStr(_currentTimeZoneId);
    } catch (_) {}

    if (_deviceRepo.getDeviceDpidMap(id).isNotEmpty) {
      notifyListeners();
      unawaited(_refreshAll(id, showLoading: false));
      return;
    }

    _optimisticOverrides.clear();
    _logs.clear();
    clearError();
    await _refreshAll(id, showLoading: true);
  }

  Future<void> _refreshAll(String id, {required bool showLoading}) async {
    if (showLoading) setLoading(true);
    try {
      await Future.wait([_deviceRepo.fetchDeviceProperties(id), fetchTodayLogs(), checkFirmwareUpdate()]);
    } catch (e) {
      setError(e.toString());
    } finally {
      if (showLoading) setLoading(false);
      notifyListeners();
    }
  }

  bool _checkOnline() {
    if (!isOnline) {
      setError(_s?.offline ?? '设备已离线');
      return false;
    }
    return true;
  }

  Future<bool> _executeWithTimeout(Future<bool> Function() action) async {
    try {
      return await action().timeout(const Duration(seconds: 3));
    } catch (_) {
      return false;
    }
  }

  Future<void> _executeOptimistic({
    required DpidValueMap optimisticChanges,
    required CommandAttrList commandPayload,
    String? errorMsg,
  }) async {
    final Map previousOverrides = Map.from(_optimisticOverrides);
    optimisticChanges.forEach((k, v) => _optimisticOverrides[k] = v);
    notifyListeners();

    final bool success = await _executeWithTimeout(() => _deviceRepo.sendDeviceCommand(_deviceId, commandPayload));

    if (!success) {
      _optimisticOverrides
        ..clear()
        ..addAll(previousOverrides.cast());
      setError(errorMsg ?? (_s?.operationFailed ?? '操作失败'));
      notifyListeners();
    }
  }

  Future<void> setWorkMode(WorkMode mode) async {
    if (!_checkOnline()) return;
    if (workMode == mode && !isDndEnabled) return;

    final CommandAttrList payload = [
      {'dpid': DeviceThingModel.deviceMode.dpid, 'value': mode.value.toString()},
    ];
    final DpidValueMap optimistic = {DeviceThingModel.deviceMode.dpid: mode.value};

    if ((mode == WorkMode.timer || mode == WorkMode.manual) && isDndEnabled) {
      payload.add({'dpid': DeviceThingModel.notdisturbModeStatus.dpid, 'value': false});
      optimistic[DeviceThingModel.notdisturbModeStatus.dpid] = false;
    }

    await _executeOptimistic(
      optimisticChanges: optimistic,
      commandPayload: payload,
      errorMsg: _s?.operationFailed ?? '切换模式失败',
    );
  }

  Future<void> toggleDnd() async {
    if (!_checkOnline()) return;
    final target = !isDndEnabled;
    await _executeOptimistic(
      optimisticChanges: {DeviceThingModel.notdisturbModeStatus.dpid: target},
      commandPayload: [
        {'dpid': DeviceThingModel.notdisturbModeStatus.dpid, 'value': target},
      ],
      errorMsg: _s?.operationFailed ?? '切换勿扰状态失败',
    );
  }

  Future<void> executeAction(ExecuteAction action) async {
    if (!_checkOnline() || isOperating) return;

    String? targetDpid;
    if (action == ExecuteAction.cleaning) {
      targetDpid = DeviceThingModel.cleanCatLitter.dpid;
    } else if (action == ExecuteAction.smoothing) {
      targetDpid = DeviceThingModel.flatCatLitter.dpid;
    } else if (action == ExecuteAction.emptying) {
      targetDpid = DeviceThingModel.emptyCatLitter.dpid;
    }
    if (targetDpid == null) return;

    await _executeOptimistic(
      optimisticChanges: {DeviceThingModel.deviceExecute.dpid: action.value},
      commandPayload: [
        {'dpid': targetDpid, 'value': true},
      ],
      errorMsg: _s?.operationFailed ?? '执行动作失败',
    );
  }

  Future<void> togglePlasma() async {
    if (!_checkOnline()) return;
    final target = !isPlasmaEnabled;
    await _executeOptimistic(
      optimisticChanges: {DeviceThingModel.palsmaState.dpid: target},
      commandPayload: [
        {'dpid': DeviceThingModel.palsmaState.dpid, 'value': target},
      ],
      errorMsg: _s?.operationFailed ?? '切换等离子状态失败',
    );
  }

  Future<void> toggleChildLock() async {
    if (!_checkOnline()) return;
    final target = !isChildLockEnabled;
    await _executeOptimistic(
      optimisticChanges: {DeviceThingModel.childLockSwitch.dpid: target},
      commandPayload: [
        {'dpid': DeviceThingModel.childLockSwitch.dpid, 'value': target},
      ],
      errorMsg: _s?.operationFailed ?? '切换童锁状态失败',
    );
  }

  // ================= 4. 设置页与二级子页面全套方法 =================

  Future<void> updateAutoModeDelay(int index) async {
    if (!_checkOnline()) return;
    final int minutes = int.parse(autoModeOptions[index]);
    final int seconds = minutes * 60;

    await _executeOptimistic(
      optimisticChanges: {DeviceThingModel.autoModeDelay.dpid: seconds},
      commandPayload: [
        {'dpid': DeviceThingModel.autoModeDelay.dpid, 'value': seconds.toString()},
      ],
      errorMsg: _s?.operationFailed ?? '自动清理延迟设置失败',
    );
  }

  Future<void> setDndTime(String start, String end) async {
    if (!_checkOnline()) return;
    final int startSec = TimeUtils.timeToSeconds(start);
    final int endSec = TimeUtils.timeToSeconds(end);
    final newJsonStr = jsonEncode({'TimerStart': startSec.toString(), 'TimerEnd': endSec.toString()});

    await _executeOptimistic(
      optimisticChanges: {DeviceThingModel.notdisturbModeSchedule.dpid: newJsonStr},
      commandPayload: [
        {'dpid': DeviceThingModel.notdisturbModeSchedule.dpid, 'value': newJsonStr},
      ],
      errorMsg: _s?.operationFailed ?? '设置勿扰时间段失败',
    );
  }

  void setTimeZone(String tzId, String offsetStr) {
    _currentTimeZoneId = tzId;
    _currentTimeZoneOffset = offsetStr;
    notifyListeners();
  }

  void addTimer(String timeStr) {
    final list = StringList.from(timerList);
    list.add(timeStr);
    list.sort();
    final jsonStr = jsonEncode(list.map((t) => TimeUtils.timeToSeconds(t).toString()).toList());
    _optimisticOverrides[DeviceThingModel.timerModeSchedule.dpid] = jsonStr;
    notifyListeners();
  }

  void removeTimer(int index) {
    final list = StringList.from(timerList);
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    final jsonStr = jsonEncode(list.map((t) => TimeUtils.timeToSeconds(t).toString()).toList());
    _optimisticOverrides[DeviceThingModel.timerModeSchedule.dpid] = jsonStr;
    notifyListeners();
  }

  Future<void> submitTimers() async {
    if (!_checkOnline()) return;
    setLoading(true);
    final timersJsonString = jsonEncode(timerList.map((time) => TimeUtils.timeToSeconds(time).toString()).toList());
    final success = await _executeWithTimeout(
      () => _deviceRepo.sendDeviceCommand(_deviceId, [
        {'dpid': DeviceThingModel.timerModeSchedule.dpid, 'value': timersJsonString},
      ]),
    );
    setLoading(false);
    if (!success) setError(_s?.operationFailed ?? '定时列表设置失败');
  }

  Future<bool> startCalibrationStep1() async {
    if (!_checkOnline()) return false;
    setLoading(true);
    final success = await _executeWithTimeout(
      () => _deviceRepo.sendDeviceCommand(_deviceId, [
        {'dpid': DeviceThingModel.prepareCalibration.dpid, 'value': true},
      ]),
    );
    setLoading(false);
    if (!success) setError(_s?.operationFailed ?? '校准启动失败');
    return success;
  }

  Future<bool> submitCalibrationStep3(int weightGrams) async {
    if (!_checkOnline()) return false;
    setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('calibration_weight_$_deviceId', weightGrams);
      _savedCalibrationWeight = weightGrams;
    } catch (_) {}

    final success = await _executeWithTimeout(
      () => _deviceRepo.sendDeviceCommand(_deviceId, [
        {'dpid': DeviceThingModel.calibrationWeight.dpid, 'value': weightGrams},
        {'dpid': DeviceThingModel.calibration.dpid, 'value': true},
      ]),
    );
    setLoading(false);
    if (!success) setError(_s?.operationFailed ?? '校准失败');
    return success;
  }

  Future<void> resetWifi() async {
    if (!_checkOnline()) return;
    setLoading(true);
    final success = await _executeWithTimeout(
      () => _deviceRepo.sendDeviceCommand(_deviceId, [
        {'dpid': DeviceThingModel.resetWlan.dpid, 'value': true},
      ]),
    );
    setLoading(false);
    if (!success) setError(_s?.operationFailed ?? '重置WiFi失败');
  }

  Future<void> setPlasmaSchedule({required int runSeconds, required int outSeconds}) async {
    if (!_checkOnline()) return;
    int safeRun = runSeconds.clamp(0, 7200);
    int safeOut = outSeconds.clamp(0, 21600);
    if (safeRun == 0 && safeOut != 0) safeRun = 60;
    if (safeOut == 0 && safeRun != 0) safeOut = 60;

    final newJsonStr = jsonEncode({'runTime': safeRun.toString(), 'outTime': safeOut.toString()});

    await _executeOptimistic(
      optimisticChanges: {DeviceThingModel.plasmaSchedule.dpid: newJsonStr},
      commandPayload: [
        {'dpid': DeviceThingModel.plasmaSchedule.dpid, 'value': newJsonStr},
      ],
      errorMsg: _s?.operationFailed ?? '设置除臭模式失败',
    );
  }

  Future<void> checkFirmwareUpdate() async {
    if (_deviceId.isEmpty) return;
    final otaData = await _deviceRepo.checkPendingFirmware(_deviceId);
    if (otaData != null && otaData['recordId'] != null) {
      _hasNewFirmware = true;
      _newFirmwareVersion = otaData['version']?.toString() ?? (_s?.latestVersion ?? '最新');
      _pendingOtaRecordId = otaData['recordId'].toString();
    } else {
      _hasNewFirmware = false;
      _newFirmwareVersion = '';
      _pendingOtaRecordId = '';
    }
    notifyListeners();
  }

  Future<bool> startFirmwareUpgrade({int timeoutSeconds = 120}) async {
    if (!_checkOnline()) return false;
    if (_pendingOtaRecordId.isEmpty) return false;

    setLoading(true);
    final targetVersion = _newFirmwareVersion;
    final success = await _deviceRepo.dispatchFirmwareUpgrade(_deviceId, _pendingOtaRecordId);
    setLoading(false);

    if (success) {
      _hasNewFirmware = false;
      _isOtaUpdating = true;
      notifyListeners();
      _startOtaPolling(_deviceId, targetVersion, timeoutSeconds);
      return true;
    } else {
      setError(_s?.operationFailed ?? '下发固件升级失败');
      return false;
    }
  }

  void _startOtaPolling(String id, String targetVersion, int timeoutSeconds) {
    _otaPollingTimer?.cancel();
    final startTime = DateTime.now();

    _otaPollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (DateTime.now().difference(startTime).inSeconds >= timeoutSeconds) {
        stopOtaPolling();
        setError(_s?.operationFailed ?? 'OTA 超时');
        notifyListeners();
        return;
      }
      await _deviceRepo.fetchDeviceProperties(id);
      if (firmwareVersion == targetVersion) {
        stopOtaPolling();
        notifyListeners();
      }
    });
  }

  void stopOtaPolling() {
    _otaPollingTimer?.cancel();
    _otaPollingTimer = null;
    _isOtaUpdating = false;
  }

  Future<bool> updateDeviceName(String newName) async {
    if (_deviceId.isEmpty) return false;
    setLoading(true);
    final ok = await _deviceRepo.renameDevice(_deviceId, newName);
    setLoading(false);
    if (!ok) setError(_s?.operationFailed ?? '重命名失败');
    return ok;
  }

  Future<bool> deleteCurrentDevice() async {
    if (_deviceId.isEmpty) return false;
    setLoading(true);
    final ok = await _deviceRepo.deleteDevice(_deviceId);
    setLoading(false);
    return ok;
  }

  Future<void> fetchTodayLogs() async {
    if (_deviceId.isEmpty) return;
    try {
      final now = DateTime.now();
      final todayStartUtc = DateTime(now.year, now.month, now.day).toUtc();
      final fromStr = "${todayStartUtc.toIso8601String().split('.').first}Z";
      final toStr = "${now.toUtc().toIso8601String().split('.').first}Z";
      final targetDpids = [DeviceThingModel.deviceExecute.dpid, DeviceThingModel.excretionTimeDay.dpid].join(',');

      final res = await _deviceRepo.fetchDeviceLogsRaw(
        _deviceId,
        dpidFilter: targetDpids,
        fromIsoUtc: fromStr,
        toIsoUtc: toStr,
      );

      if (res.data != null) {
        final List items = (res.data!['items'] is List) ? res.data!['items'] as List : [];
        final DeviceLogList loaded = [];

        for (final item in items) {
          if (item is! Map) continue;
          final String tsStr = item['ts']?.toString() ?? '';
          final List values = (item['values'] is List) ? item['values'] as List : [];
          if (tsStr.isEmpty || values.isEmpty) continue;
          final time = DateTime.parse(tsStr).toLocal();

          for (final valObj in values) {
            if (valObj is! Map) continue;
            final dpid = valObj['dpid']?.toString();
            final value = valObj['value'];
            if (dpid == DeviceThingModel.deviceExecute.dpid) {
              final act = ExecuteAction.fromValue(int.tryParse(value.toString()) ?? 0);
              if (act != ExecuteAction.idle && act != ExecuteAction.resetting) {
                loaded.add(DeviceLog(time: time, content: act.name, isAction: true));
              }
            } else if (dpid == DeviceThingModel.excretionTimeDay.dpid) {
              final sec = int.tryParse(value.toString()) ?? 0;
              if (sec > 0) {
                loaded.add(DeviceLog(time: time, content: sec.toString(), isAction: false));
              }
            }
          }
        }
        _logs
          ..clear()
          ..addAll(loaded);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('获取猫砂盆今日日志异常: $e');
    }
  }
}
