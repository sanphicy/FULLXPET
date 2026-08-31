import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/core/services/nav_service.dart';
import 'package:fullxpet/locator.dart';
import 'package:fullxpet/features/device/repositories/device_repository.dart';
import 'package:fullxpet/features/device/models/device_dto.dart';
import 'package:fullxpet/features/device/models/device_thing_model.dart';

class ActiveDeviceProvider extends BaseProvider with WidgetsBindingObserver {
  final DeviceRepository _deviceRepo = locator<DeviceRepository>();

  DeviceDto? _currentDevice;
  DeviceDto? get currentDevice => _currentDevice;

  StreamSubscription<String>? _repoSubscription;
  Timer? _otaPollingTimer;

  // 1. 全部委托给 _currentDevice，保留对外 Getter 确保 UI 0 成本无缝兼容
  List<String> get timerList => _currentDevice?.timerList ?? [];
  bool get hasNewFirmware => _currentDevice?.hasNewFirmware ?? false;
  String get newFirmwareVersion => _currentDevice?.newFirmwareVersion ?? '';
  bool get isOtaUpdating => _currentDevice?.isOtaUpdating ?? false;
  int get savedCalibrationWeight => _currentDevice?.savedCalibrationWeight ?? 5000;
  String get currentTimeZoneId => _currentDevice?.timeZoneId ?? 'Asia/Shanghai';
  String get currentTimeZoneOffset => _currentDevice?.timeZoneOffset ?? 'UTC+08:00';
  int get autoModeIndex => _currentDevice?.autoModeIndex ?? 0;
  bool get isNetworkGood => true;

  final List<String> autoModeOptions = const ['1', '2', '3', '4', '5'];

  S? get _s {
    final BuildContext? ctx = NavService.rootNavigatorKey.currentContext;
    return ctx != null ? S.of(ctx) : null;
  }

  ActiveDeviceProvider() {
    _repoSubscription = _deviceRepo.onDeviceUpdated.listen((updatedDeviceId) {
      if (_currentDevice != null && _currentDevice!.deviceId == updatedDeviceId) {
        notifyListeners();
      }
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    stopOtaPolling();
    WidgetsBinding.instance.removeObserver(this);
    _repoSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _currentDevice != null) {
      _deviceRepo.fetchDeviceProperties(_currentDevice!.deviceId);
    }
  }

  bool _checkOffline() {
    if (_currentDevice == null) return false;
    if (!_currentDevice!.isOnline) {
      setError(_s?.offline ?? 'offline');
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
    required Map<String, dynamic> newAttrs,
    required Map<String, dynamic> oldAttrs,
    required Future<bool> Function() apiCall,
    String? errorMsg,
  }) async {
    _currentDevice!.updateAttributesFromMap(newAttrs);
    notifyListeners();

    final success = await _executeWithTimeout(apiCall);
    if (!success) {
      _currentDevice!.updateAttributesFromMap(oldAttrs);
      setError(errorMsg ?? _s?.operationFailed ?? 'Operation Failed');
      notifyListeners();
    }
  }

  // 选择并激活当前设备
  Future<void> selectDevice(String id) async {
    if (_currentDevice?.deviceId == id) return;
    _currentDevice = _deviceRepo.getDevice(id);

    try {
      final prefs = await SharedPreferences.getInstance();
      _currentDevice!.savedCalibrationWeight = prefs.getInt('calibration_weight_$id') ?? 5000;
      _currentDevice!.timeZoneId = await FlutterTimezone.getLocalTimezone();
      _currentDevice!.timeZoneOffset = _calculateOffsetStr(_currentDevice!.timeZoneId);
    } catch (_) {}

    clearError();
    notifyListeners();

    final needsLoading = _currentDevice!.wifiMac == '00:00:00:00:00:00';
    if (needsLoading) setLoading(true);

    try {
      await _deviceRepo.fetchDeviceProperties(id);
      await _deviceRepo.fetchDeviceLogs(id, isLoadMore: false);

      final otaData = await _deviceRepo.checkPendingFirmware(id);
      if (otaData != null && otaData['recordId'] != null) {
        _currentDevice!.hasNewFirmware = true;
        _currentDevice!.newFirmwareVersion = otaData['version']?.toString() ?? (_s?.latestVersion ?? '最新');
        _currentDevice!.pendingOtaRecordId = otaData['recordId'].toString();
      } else {
        _currentDevice!.hasNewFirmware = false;
        _currentDevice!.newFirmwareVersion = '';
        _currentDevice!.pendingOtaRecordId = '';
      }
    } catch (e) {
      setError(e.toString());
    } finally {
      if (needsLoading) setLoading(false);
      notifyListeners();
    }
  }

  // 切换工作模式
  Future<void> setMode(WorkMode mode) async {
    if (!_checkOffline()) return;
    if (_currentDevice!.workMode == mode) return;

    if ((mode == WorkMode.timer || mode == WorkMode.manual) && _currentDevice!.isDndEnabled) {
      toggleDnd(false);
    }

    final previousMode = _currentDevice!.workMode;
    final attrs = <Map<String, dynamic>>[
      {'dpid': DeviceThingModel.deviceMode.dpid, 'value': mode.value.toString()},
    ];

    if (mode == WorkMode.timer) {
      attrs.add({
        'dpid': DeviceThingModel.timerModeSchedule.dpid,
        'value': jsonEncode(["0", "28800"]),
      });
    }

    await _executeOptimistic(
      newAttrs: {DeviceThingModel.deviceMode.dpid: mode.value.toString()},
      oldAttrs: {DeviceThingModel.deviceMode.dpid: previousMode.value.toString()},
      apiCall: () => _deviceRepo.sendDeviceCommand(_currentDevice!.deviceId, attrs),
      errorMsg: _s?.operationFailed ?? 'Failed to set mode',
    );
  }

  // 开关勿扰模式
  Future<void> toggleDnd(bool isBool) async {
    if (!_checkOffline()) return;

    final previousState = _currentDevice!.isDndEnabled;
    final targetState = !previousState;

    if (!isBool && (_currentDevice!.workMode != WorkMode.auto)) {
      setMode(WorkMode.auto);
    }

    await _executeOptimistic(
      newAttrs: {DeviceThingModel.notdisturbModeStatus.dpid: targetState},
      oldAttrs: {DeviceThingModel.notdisturbModeStatus.dpid: previousState},
      apiCall: () => _deviceRepo.sendDeviceCommand(_currentDevice!.deviceId, [
        {'dpid': DeviceThingModel.notdisturbModeStatus.dpid, 'value': targetState},
      ]),
      errorMsg: _s?.operationFailed ?? 'Failed to toggle DND',
    );
  }

  // 执行动作
  Future<void> executeAction(ExecuteAction action) async {
    if (!_checkOffline()) return;

    String? targetDpid;
    if (action == ExecuteAction.cleaning) {
      targetDpid = DeviceThingModel.cleanCatLitter.dpid;
    } else if (action == ExecuteAction.smoothing) {
      targetDpid = DeviceThingModel.flatCatLitter.dpid;
    }
    if (targetDpid == null) return;

    final previousAction = _currentDevice!.executeAction;
    await _executeOptimistic(
      newAttrs: {DeviceThingModel.deviceExecute.dpid: action.value.toString()},
      oldAttrs: {DeviceThingModel.deviceExecute.dpid: previousAction.value.toString()},
      apiCall: () => _deviceRepo.sendDeviceCommand(_currentDevice!.deviceId, [
        {'dpid': targetDpid!, 'value': true},
      ]),
      errorMsg: _s?.operationFailed ?? 'Failed to execute action',
    );
  }

  // 开关童锁
  Future<void> toggleChildLock() async {
    if (!_checkOffline()) return;

    final previousState = _currentDevice!.isChildLockEnabled;
    final targetState = !previousState;

    await _executeOptimistic(
      newAttrs: {DeviceThingModel.childLockSwitch.dpid: targetState},
      oldAttrs: {DeviceThingModel.childLockSwitch.dpid: previousState},
      apiCall: () => _deviceRepo.sendDeviceCommand(_currentDevice!.deviceId, [
        {'dpid': DeviceThingModel.childLockSwitch.dpid, 'value': targetState},
      ]),
      errorMsg: _s?.operationFailed ?? 'Failed to toggle child lock',
    );
  }

  // 开关等离子
  Future<void> togglePlasma() async {
    if (!_checkOffline()) return;

    final previousState = _currentDevice!.isPlasmaEnabled;
    final targetState = !previousState;

    await _executeOptimistic(
      newAttrs: {DeviceThingModel.palsmaState.dpid: targetState},
      oldAttrs: {DeviceThingModel.palsmaState.dpid: previousState},
      apiCall: () => _deviceRepo.sendDeviceCommand(_currentDevice!.deviceId, [
        {'dpid': DeviceThingModel.palsmaState.dpid, 'value': targetState},
      ]),
      errorMsg: _s?.operationFailed ?? 'Failed to toggle plasma',
    );
  }

  // 更新自动模式延时
  void updateAutoMode(int index) async {
    if (!_checkOffline()) return;
    int minutes = int.parse(autoModeOptions[index]);
    int seconds = minutes * 60;

    final previousSeconds = _currentDevice!.autoModeDelaySeconds;

    await _executeOptimistic(
      newAttrs: {DeviceThingModel.autoModeDelay.dpid: seconds.toString()},
      oldAttrs: {DeviceThingModel.autoModeDelay.dpid: previousSeconds.toString()},
      apiCall: () => _deviceRepo.sendDeviceCommand(_currentDevice!.deviceId, [
        {'dpid': DeviceThingModel.autoModeDelay.dpid, 'value': seconds.toString()},
      ]),
      errorMsg: _s?.operationFailed ?? 'Failed to update auto mode',
    );
  }

  // 设置勿扰时间段
  void setDndTime(String start, String end) async {
    if (!_checkOffline()) return;

    int startSec = _timeToSeconds(start);
    int endSec = _timeToSeconds(end);

    final previousRange = _currentDevice!.dndTimeRange;
    final oldStartSec = _timeToSeconds(previousRange['start']!);
    final oldEndSec = _timeToSeconds(previousRange['end']!);

    final newJsonStr = jsonEncode({'TimerStart': startSec.toString(), 'TimerEnd': endSec.toString()});
    final oldJsonStr = jsonEncode({'TimerStart': oldStartSec.toString(), 'TimerEnd': oldEndSec.toString()});

    await _executeOptimistic(
      newAttrs: {DeviceThingModel.notdisturbModeSchedule.dpid: newJsonStr},
      oldAttrs: {DeviceThingModel.notdisturbModeSchedule.dpid: oldJsonStr},
      apiCall: () => _deviceRepo.sendDeviceCommand(_currentDevice!.deviceId, [
        {'dpid': DeviceThingModel.notdisturbModeSchedule.dpid, 'value': newJsonStr},
      ]),
      errorMsg: _s?.operationFailed ?? 'Failed to set DND time',
    );
  }

  // 设置时区
  void setTimeZone(String tzId, String offsetStr) {
    if (_currentDevice == null) return;
    _currentDevice!.timeZoneId = tzId;
    _currentDevice!.timeZoneOffset = offsetStr;
    notifyListeners();
  }

  // 添加定时
  void addTimer(String timeStr) {
    if (_currentDevice == null) return;
    final list = List<String>.from(_currentDevice!.timerList);
    list.add(timeStr);
    list.sort();
    final jsonStr = jsonEncode(list.map((t) => _timeToSeconds(t).toString()).toList());
    _currentDevice!.updateAttributesFromMap({DeviceThingModel.timerModeSchedule.dpid: jsonStr});
    notifyListeners();
  }

  // 移除定时
  void removeTimer(int index) {
    if (_currentDevice == null) return;
    final list = List<String>.from(_currentDevice!.timerList);
    list.removeAt(index);
    final jsonStr = jsonEncode(list.map((t) => _timeToSeconds(t).toString()).toList());
    _currentDevice!.updateAttributesFromMap({DeviceThingModel.timerModeSchedule.dpid: jsonStr});
    notifyListeners();
  }

  // 提交定时列表
  Future<void> submitTimers() async {
    if (!_checkOffline()) return;
    setLoading(true);

    final timersJsonString = jsonEncode(
      _currentDevice!.timerList.map((time) => _timeToSeconds(time).toString()).toList(),
    );

    final success = await _executeWithTimeout(
      () => _deviceRepo.sendDeviceCommand(_currentDevice!.deviceId, [
        {'dpid': DeviceThingModel.timerModeSchedule.dpid, 'value': timersJsonString},
      ]),
    );

    setLoading(false);
    if (!success) setError(_s?.operationFailed ?? 'Failed to save timers');
  }

  // 称重校准第 1 步
  Future<bool> startCalibrationStep1() async {
    if (!_checkOffline()) return false;
    setLoading(true);
    final success = await _executeWithTimeout(
      () => _deviceRepo.sendDeviceCommand(_currentDevice!.deviceId, [
        {'dpid': DeviceThingModel.prepareCalibration.dpid, 'value': true},
      ]),
    );
    setLoading(false);
    if (!success) setError(_s?.operationFailed ?? 'Calibration start failed');
    return success;
  }

  // 称重校准第 3 步
  Future<bool> submitCalibrationStep3(int weightGrams) async {
    if (!_checkOffline()) return false;
    setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('calibration_weight_${_currentDevice!.deviceId}', weightGrams);
      _currentDevice!.savedCalibrationWeight = weightGrams;
    } catch (_) {}

    final success = await _executeWithTimeout(
      () => _deviceRepo.sendDeviceCommand(_currentDevice!.deviceId, [
        {'dpid': DeviceThingModel.calibrationWeight.dpid, 'value': weightGrams},
        {'dpid': DeviceThingModel.calibration.dpid, 'value': true},
      ]),
    );
    setLoading(false);
    if (!success) setError(_s?.operationFailed ?? 'Calibration submit failed');
    return success;
  }

  // 重置 Wi-Fi
  Future<void> resetWifi() async {
    if (!_checkOffline()) return;
    setLoading(true);
    final success = await _executeWithTimeout(
      () => _deviceRepo.sendDeviceCommand(_currentDevice!.deviceId, [
        {'dpid': DeviceThingModel.resetWlan.dpid, 'value': true},
      ]),
    );
    setLoading(false);
    if (!success) setError(_s?.operationFailed ?? 'Failed to reset Wi-Fi');
  }

  // 固件升级
  Future<bool> startFirmwareUpgrade({int timeoutSeconds = 120}) async {
    if (!_checkOffline()) return false;
    if (_currentDevice!.pendingOtaRecordId.isEmpty) {
      setError(_s?.operationFailed ?? 'No pending firmware');
      return false;
    }

    setLoading(true);
    final targetVersion = _currentDevice!.newFirmwareVersion;
    final success = await _deviceRepo.dispatchFirmwareUpgrade(
      _currentDevice!.deviceId,
      _currentDevice!.pendingOtaRecordId,
    );
    setLoading(false);

    if (success) {
      _currentDevice!.hasNewFirmware = false;
      _currentDevice!.isOtaUpdating = true;
      notifyListeners();
      _startOtaPolling(_currentDevice!.deviceId, targetVersion, timeoutSeconds);
      return true;
    } else {
      setError(_s?.operationFailed ?? 'Dispatch firmware failed');
      return false;
    }
  }

  void _startOtaPolling(String deviceId, String targetVersion, int timeoutSeconds) {
    _otaPollingTimer?.cancel();
    final startTime = DateTime.now();

    _otaPollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (DateTime.now().difference(startTime).inSeconds >= timeoutSeconds) {
        stopOtaPolling();
        setError(_s?.operationFailed ?? 'OTA timeout');
        notifyListeners();
        return;
      }

      try {
        await _deviceRepo.fetchDeviceProperties(deviceId);
        if (_currentDevice != null && _currentDevice!.firmwareVersion == targetVersion) {
          stopOtaPolling();
          notifyListeners();
        }
      } catch (e) {
        debugPrint('OTA Polling Exception: $e');
      }
    });
  }

  void stopOtaPolling() {
    _otaPollingTimer?.cancel();
    _otaPollingTimer = null;
    if (_currentDevice != null) {
      _currentDevice!.isOtaUpdating = false;
    }
  }

  // 重命名设备
  Future<bool> updateDeviceName(String newName) async {
    if (_currentDevice == null) return false;
    setLoading(true);
    final success = await _deviceRepo.renameDevice(_currentDevice!.deviceId, newName);
    setLoading(false);
    if (!success) setError(_s?.operationFailed ?? 'Failed to rename');
    return success;
  }

  int _timeToSeconds(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 3600 + m * 60;
  }

  String _calculateOffsetStr(String tzName) {
    try {
      final location = tz.getLocation(tzName);
      final offset = tz.TZDateTime.now(location).timeZoneOffset;
      final hours = offset.inHours;
      final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
      final sign = hours >= 0 ? '+' : '-';
      return 'UTC$sign${hours.abs().toString().padLeft(2, '0')}:$minutes';
    } catch (_) {
      return 'UTC+00:00';
    }
  }
}
