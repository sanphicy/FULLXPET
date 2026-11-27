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
import 'package:fullxpet/features/device/constants/product_constants.dart';
import 'package:fullxpet/features/device/models/device_hardware_info.dart';
import 'package:fullxpet/features/device/models/device_item_dto.dart';
import 'package:fullxpet/features/device/models/device_log.dart';
import 'package:fullxpet/features/device/models/mqtt_attr_report_dto.dart';
import 'package:fullxpet/features/device/models/product_dto.dart';
import 'package:fullxpet/features/device/products/litter_box/models/device_thing_model.dart';
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

  static const int _logPageSize = 20;
  static const int _maxEmptyPageAutoAdvance = 5;

  bool _isDisposed = false;
  bool _isLoadingLogs = false;
  bool _isLoadingMoreLogs = false;
  bool _hasMoreLogs = false;
  String? _nextLogPageToken;
  String? _logsWindowFromIso;
  String? _logsWindowToIso;
  int _logsRequestSeq = 0;
  final Set<String> _seenPageTokens = {};
  final Set<String> _seenLogKeys = {};

  bool get isLoadingLogs => _isLoadingLogs;
  bool get isLoadingMoreLogs => _isLoadingMoreLogs;
  bool get hasMoreLogs => _hasMoreLogs;

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

  String get currentTimeZoneOffset {
    final dpVal = _getDpid(DeviceThingModel.timeZone)?.toString().trim() ?? '';
    if (dpVal.isNotEmpty) {
      final hours = double.tryParse(dpVal);
      if (hours != null) {
        final totalMinutes = (hours * 60).round();
        final sign = totalMinutes >= 0 ? '+' : '-';
        final absH = (totalMinutes.abs() ~/ 60).toString().padLeft(2, '0');
        final absM = (totalMinutes.abs() % 60).toString().padLeft(2, '0');
        return 'UTC$sign$absH:$absM';
      }
      return dpVal;
    }
    return _currentTimeZoneOffset;
  }

  bool get isNetworkGood => true;

  final StringList autoModeOptions = const ['1', '2', '3', '4', '5'];

  StreamSubscription? _repoSub;
  StreamSubscription? _dpidSub;
  StreamSubscription<MqttAttrReportDto>? _mqttReportSub;
  Timer? _optimisticResetTimer;

  LitterBoxViewModel() {
    _dpidSub = _deviceRepo.onDpidUpdated.listen((event) {
      if (_isDisposed) return;
      if (_deviceId.isNotEmpty && event.deviceId == _deviceId && _optimisticOverrides.isNotEmpty) {
        for (final dpid in event.dpids) {
          _optimisticOverrides.remove(dpid);
        }
        if (event.dpids.contains(DeviceThingModel.deviceStatus.dpid) ||
            event.dpids.contains(DeviceThingModel.deviceExecute.dpid)) {
          _optimisticOverrides.remove(DeviceThingModel.deviceExecute.dpid);
          _optimisticOverrides.remove(DeviceThingModel.deviceStatus.dpid);
        }
      }
    });
    _mqttReportSub = _deviceRepo.onMqttAttrReport.listen(_handleMqttLogReport);
    _repoSub = _deviceRepo.onDeviceUpdated.listen((updatedId) {
      if (_isDisposed) return;
      if (_deviceId.isNotEmpty && (updatedId == _deviceId || updatedId == 'ALL')) {
        notifyListeners();
      }
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _logsRequestSeq++;
    _optimisticResetTimer?.cancel();
    stopOtaPolling();
    WidgetsBinding.instance.removeObserver(this);
    _mqttReportSub?.cancel();
    _dpidSub?.cancel();
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

  String get productId => basicInfo?.productId ?? '';

  /// 严格通过 productId 判断型号与硬件特性
  bool get isV4 => productId == ProductConstants.pidLitterBoxV4;
  String get modelBadge => isV4 ? 'V4' : 'V3';
  bool get supportPlasma => !isV4;
  bool get supportWeighing => !isV4;

  ProductDto? get productInfo => _deviceRepo.getProduct(productId);

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

  static const int litterRecommendedMinGrams = 2500;
  static const int litterRecommendedMaxGrams = 3500;

  int get litterWeightGrams => int.tryParse(_getDpid(DeviceThingModel.litterWeight)?.toString() ?? '0') ?? 0;
  double get litterPercent => (litterWeightGrams / litterRecommendedMaxGrams).clamp(0.0, 1.0);

  int get shitWeightGrams => int.tryParse(_getDpid(DeviceThingModel.shitWeight)?.toString() ?? '0') ?? 0;

  ExecuteAction get currentAction {
    if (!isOnline) return ExecuteAction.idle;
    final rawExec = int.tryParse(_getDpid(DeviceThingModel.deviceExecute)?.toString() ?? '') ?? 0;
    return ExecuteAction.fromValue(rawExec);
  }

  String get deviceStatusCode => _getDpid(DeviceThingModel.deviceStatus)?.toString().trim() ?? '0';

  bool get isPaused => isOnline && deviceStatusCode == '2';

  bool get isOperating {
    if (!isOnline) return false;
    final exec = _getDpid(DeviceThingModel.deviceExecute)?.toString().trim() ?? '0';
    return deviceStatusCode != '0' || exec != '0';
  }

  /// 顶部状态胶囊统一文案（与 isOperating 保持完全一致的判定口径）
  String resolveStatusLabel(S s) {
    if (!isOnline) return s.offline;
    if (isPaused) return '已暂停';
    if (currentAction != ExecuteAction.idle) {
      return currentAction.getLocalizedLabel(s);
    }
    if (isOperating) return '运行中';
    return s.actionIdle;
  }

  /// 卡扣状态 (DP 21)：true=已扣紧，false=未扣紧；离线或未上报返回 null
  bool? get isBuckleFastened {
    if (!isOnline) return null;
    final val = _getDpid(DeviceThingModel.installLoose);
    if (val == null) return null;
    if (val is bool) return val;
    final str = val.toString().trim().toLowerCase();
    if (str == 'true' || str == '1') return true;
    if (str == 'false' || str == '0') return false;
    return null;
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

  String get dndRangeText => '${dndTimeRange['start']} - ${dndTimeRange['end']}';

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
    final bool isSwitchingDevice = _deviceId.isNotEmpty && _deviceId != id;
    _deviceId = id;
    _optimisticResetTimer?.cancel();
    _optimisticOverrides.clear();
    clearError();
    if (isSwitchingDevice) {
      _resetLogsState();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      _savedCalibrationWeight = prefs.getInt('calibration_weight_$id') ?? 5000;
      _currentTimeZoneId = await FlutterTimezone.getLocalTimezone();
      _currentTimeZoneOffset = TimeUtils.calculateOffsetStr(_currentTimeZoneId);
    } catch (_) {}

    if (_deviceRepo.getDeviceDpidMap(id).isNotEmpty) {
      notifyListeners();
      await _refreshAll(id, showLoading: false);
      return;
    }

    _resetLogsState();
    await _refreshAll(id, showLoading: true);
  }

  Future<void> _refreshAll(String id, {required bool showLoading}) async {
    if (showLoading) setLoading(true);
    try {
      await _deviceRepo.ensureDeviceBasicLoaded(id);
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

  Future<bool> _executeOptimistic({
    required DpidValueMap optimisticChanges,
    required CommandAttrList commandPayload,
    String? errorMsg,
  }) async {
    clearError();
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
      return false;
    }

    // 指令下发成功后，若 6 秒内未收到 MQTT 对应 DP 确认，仅移除本次乐观项并拉取最新状态兜底
    final pendingKeys = optimisticChanges.keys.toSet();
    _optimisticResetTimer?.cancel();
    _optimisticResetTimer = Timer(const Duration(seconds: 6), () {
      if (_isDisposed || _deviceId.isEmpty) return;
      bool removed = false;
      for (final key in pendingKeys) {
        if (_optimisticOverrides.remove(key) != null) removed = true;
      }
      if (removed) {
        _deviceRepo.fetchDeviceProperties(_deviceId);
        notifyListeners();
      }
    });
    return true;
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

  String _formatTimeZoneDpValue(Duration offset) {
    return (offset.inMinutes / 60.0).toString();
  }

  Future<bool> setTimeZone({required String tzId, required String offsetStr, required Duration offset}) async {
    if (!_checkOnline()) return false;

    final dpValue = _formatTimeZoneDpValue(offset);

    final ok = await _executeOptimistic(
      optimisticChanges: {DeviceThingModel.timeZone.dpid: dpValue},
      commandPayload: [
        {'dpid': DeviceThingModel.timeZone.dpid, 'value': dpValue},
      ],
      errorMsg: _s?.operationFailed ?? '设置时区失败',
    );

    if (ok) {
      _currentTimeZoneId = tzId;
      _currentTimeZoneOffset = offsetStr;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> submitTimers(StringList timers) async {
    if (!_checkOnline()) return false;
    final sorted = timers.toSet().toList()..sort();
    final timersJsonString = jsonEncode(sorted.map((time) => TimeUtils.timeToSeconds(time).toString()).toList());

    return await _executeOptimistic(
      optimisticChanges: {DeviceThingModel.timerModeSchedule.dpid: timersJsonString},
      commandPayload: [
        {'dpid': DeviceThingModel.timerModeSchedule.dpid, 'value': timersJsonString},
      ],
      errorMsg: _s?.operationFailed ?? '定时列表设置失败',
    );
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
    if (_isDisposed) return;
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
      if (_isDisposed) {
        stopOtaPolling();
        return;
      }
      if (DateTime.now().difference(startTime).inSeconds >= timeoutSeconds) {
        stopOtaPolling();
        setError(_s?.operationFailed ?? 'OTA 超时');
        notifyListeners();
        return;
      }
      await _deviceRepo.fetchDeviceProperties(id);
      if (_isDisposed) return;
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

  // ================= 5. 今日日志分页与 MQTT 实时入列 =================

  String get _logDpidFilter => [
    DeviceThingModel.resetWlan.dpid,
    DeviceThingModel.deviceExecute.dpid,
    DeviceThingModel.catEntry.dpid,
    DeviceThingModel.calibration.dpid,
    DeviceThingModel.excretionTimeDay.dpid,
  ].join(',');

  String _formatIsoUtc(DateTime dt) => '${dt.toUtc().toIso8601String().split('.').first}Z';

  bool _isTruthy(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final str = value?.toString().trim().toLowerCase() ?? '';
    return str == 'true' || str == '1';
  }

  void _resetLogsState() {
    _logsRequestSeq++;
    _logs.clear();
    _seenLogKeys.clear();
    _seenPageTokens.clear();
    _nextLogPageToken = null;
    _logsWindowFromIso = null;
    _logsWindowToIso = null;
    _hasMoreLogs = false;
    _isLoadingLogs = false;
    _isLoadingMoreLogs = false;
  }

  ({DeviceLog log, String valKey})? _buildLogEntry(String dpid, dynamic rawVal, DateTime localTime) {
    if (dpid == DeviceThingModel.deviceExecute.dpid) {
      final act = ExecuteAction.fromValue(int.tryParse(rawVal?.toString() ?? '') ?? 0);
      if (act == ExecuteAction.idle || act == ExecuteAction.resetting) return null;
      return (
        log: DeviceLog(time: localTime, type: DeviceLogType.executeAction, content: act.name),
        valKey: '${act.value}',
      );
    }
    if (dpid == DeviceThingModel.excretionTimeDay.dpid) {
      final sec = int.tryParse(rawVal?.toString() ?? '') ?? 0;
      if (sec <= 0) return null;
      return (log: DeviceLog(time: localTime, type: DeviceLogType.catToilet, content: sec.toString()), valKey: '$sec');
    }
    if (dpid == DeviceThingModel.catEntry.dpid) {
      if (!_isTruthy(rawVal)) return null;
      return (log: DeviceLog(time: localTime, type: DeviceLogType.catEntry), valKey: 'true');
    }
    if (dpid == DeviceThingModel.calibration.dpid) {
      if (!_isTruthy(rawVal)) return null;
      return (log: DeviceLog(time: localTime, type: DeviceLogType.calibration), valKey: 'true');
    }
    if (dpid == DeviceThingModel.resetWlan.dpid) {
      if (!_isTruthy(rawVal)) return null;
      return (log: DeviceLog(time: localTime, type: DeviceLogType.resetWifi), valKey: 'true');
    }
    return null;
  }

  void _handleMqttLogReport(MqttAttrReportDto report) {
    if (_isDisposed || _deviceId.isEmpty || report.deviceId != _deviceId) return;
    final changes = report.changedAttributes.isNotEmpty ? report.changedAttributes : report.functionalAttributes;
    if (changes.isEmpty) return;

    final eventTimeUtc = (report.at != null && report.at! > 0)
        ? DateTime.fromMillisecondsSinceEpoch(report.at!, isUtc: true)
        : DateTime.now().toUtc();
    final localTime = eventTimeUtc.toLocal();
    final tsMs = eventTimeUtc.millisecondsSinceEpoch;

    final DeviceLogList incoming = [];
    changes.forEach((dpid, rawVal) {
      final built = _buildLogEntry(dpid, rawVal, localTime);
      if (built == null) return;
      final key = '$tsMs|$dpid|${built.valKey}';
      if (_seenLogKeys.contains(key)) return;
      _seenLogKeys.add(key);
      incoming.add(built.log);
    });

    if (incoming.isNotEmpty) {
      _logs.insertAll(0, incoming);
      notifyListeners();
    }
  }

  List<DeviceLog> _parseLogItems(
    List<DeviceLogRawItem> items, {
    required Set<String> batchKeys,
    Set<String>? existingKeys,
  }) {
    final DeviceLogList parsed = [];
    for (final item in items) {
      final parsedUtc = DateTime.tryParse(item.ts)?.toUtc();
      if (parsedUtc == null || item.values.isEmpty) continue;
      final localTime = parsedUtc.toLocal();
      final tsMs = parsedUtc.millisecondsSinceEpoch;

      for (final valObj in item.values) {
        final built = _buildLogEntry(valObj.dpid, valObj.value, localTime);
        if (built == null) continue;
        final key = '$tsMs|${valObj.dpid}|${built.valKey}';
        if (batchKeys.contains(key) || (existingKeys?.contains(key) ?? false)) continue;

        batchKeys.add(key);
        parsed.add(built.log);
      }
    }
    return parsed;
  }

  /// 拉取今日日志第 1 页（锁定本次时间窗口；若整页均为过滤噪声则自动续拉，最多 5 页）
  Future<void> fetchTodayLogs() async {
    if (_isDisposed || _deviceId.isEmpty) return;

    final int seq = ++_logsRequestSeq;
    _isLoadingLogs = true;
    _isLoadingMoreLogs = false;
    notifyListeners();

    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final fromIso = _formatIsoUtc(todayStart);
      final toIso = _formatIsoUtc(now);

      final DeviceLogList loaded = [];
      final Set<String> seenKeys = {};
      final Set<String> seenTokens = {};
      String? currentToken;
      String? nextToken;
      bool hasMore = false;

      for (int attempt = 0; attempt < _maxEmptyPageAutoAdvance; attempt++) {
        final page = await _deviceRepo.fetchDeviceLogsPage(
          _deviceId,
          dpidFilter: _logDpidFilter,
          fromIsoUtc: fromIso,
          toIsoUtc: toIso,
          pageSize: _logPageSize,
          sort: 'desc',
          pageToken: currentToken,
        );
        if (_isDisposed || seq != _logsRequestSeq) return;

        if (currentToken != null) {
          seenTokens.add(currentToken);
        }

        loaded.addAll(_parseLogItems(page.items, batchKeys: seenKeys));

        nextToken = page.nextPageToken;
        hasMore = page.hasMore && nextToken != null && nextToken.isNotEmpty && !seenTokens.contains(nextToken);

        if (!hasMore || loaded.isNotEmpty) break;
        currentToken = nextToken;
      }

      _logsWindowFromIso = fromIso;
      _logsWindowToIso = toIso;
      _nextLogPageToken = hasMore ? nextToken : null;
      _hasMoreLogs = hasMore;
      _seenPageTokens
        ..clear()
        ..addAll(seenTokens);
      _seenLogKeys
        ..clear()
        ..addAll(seenKeys);
      _logs
        ..clear()
        ..addAll(loaded);
    } catch (e) {
      debugPrint('获取猫砂盆今日日志异常: $e');
    } finally {
      if (!_isDisposed && seq == _logsRequestSeq) {
        _isLoadingLogs = false;
        notifyListeners();
      }
    }
  }

  /// 上拉触底无感加载今日下一页日志
  Future<void> loadMoreTodayLogs() async {
    if (_isDisposed || _deviceId.isEmpty || _isLoadingLogs || _isLoadingMoreLogs || !_hasMoreLogs) {
      return;
    }

    final fromIso = _logsWindowFromIso;
    final toIso = _logsWindowToIso;
    String? currentToken = _nextLogPageToken;
    if (fromIso == null || toIso == null || currentToken == null || currentToken.isEmpty) {
      _hasMoreLogs = false;
      notifyListeners();
      return;
    }

    final int seq = _logsRequestSeq;
    _isLoadingMoreLogs = true;
    notifyListeners();

    try {
      final DeviceLogList added = [];
      final Set<String> batchKeys = {};
      final Set<String> batchTokens = {};
      String? nextToken = currentToken;
      bool hasMore = true;

      for (int attempt = 0; attempt < _maxEmptyPageAutoAdvance; attempt++) {
        if (currentToken == null ||
            currentToken.isEmpty ||
            _seenPageTokens.contains(currentToken) ||
            batchTokens.contains(currentToken)) {
          hasMore = false;
          nextToken = null;
          break;
        }

        final page = await _deviceRepo.fetchDeviceLogsPage(
          _deviceId,
          dpidFilter: _logDpidFilter,
          fromIsoUtc: fromIso,
          toIsoUtc: toIso,
          pageSize: _logPageSize,
          sort: 'desc',
          pageToken: currentToken,
        );
        if (_isDisposed || seq != _logsRequestSeq) return;

        batchTokens.add(currentToken);
        added.addAll(_parseLogItems(page.items, batchKeys: batchKeys, existingKeys: _seenLogKeys));

        nextToken = page.nextPageToken;
        hasMore =
            page.hasMore &&
            nextToken != null &&
            nextToken.isNotEmpty &&
            !_seenPageTokens.contains(nextToken) &&
            !batchTokens.contains(nextToken);

        if (!hasMore || added.isNotEmpty) break;
        currentToken = nextToken;
      }

      _seenPageTokens.addAll(batchTokens);
      _seenLogKeys.addAll(batchKeys);
      _logs.addAll(added);
      _nextLogPageToken = hasMore ? nextToken : null;
      _hasMoreLogs = hasMore;
    } catch (e) {
      debugPrint('加载更多猫砂盆今日日志异常: $e');
    } finally {
      if (!_isDisposed && seq == _logsRequestSeq) {
        _isLoadingMoreLogs = false;
        notifyListeners();
      }
    }
  }
}
