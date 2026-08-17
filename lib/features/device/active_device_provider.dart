import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/common/widgets/app_dialogs.dart';
import 'package:fullxpet/core/navigation/nav_service.dart';
import 'package:fullxpet/locator.dart';
import 'package:fullxpet/features/device/repositories/device_repository.dart';
import 'package:fullxpet/features/device/models/device_dto.dart';
import 'package:fullxpet/features/device/models/device_thing_model.dart';

class ActiveDeviceProvider extends BaseProvider with WidgetsBindingObserver {
  final DeviceRepository _deviceRepo = locator<DeviceRepository>();

  DeviceDto? _currentDevice;
  DeviceDto? get currentDevice => _currentDevice;

  StreamSubscription<String>? _repoSubscription;

  String _pendingOtaRecordId = '';
  String _currentTimeZoneId = 'Asia/Shanghai';
  String get currentTimeZoneId => _currentTimeZoneId;

  String _currentTimeZoneOffset = 'UTC+08:00';
  String get currentTimeZoneOffset => _currentTimeZoneOffset;

  List<String> _localTimerList = [];
  List<String> get timerList => _localTimerList;

  bool _hasNewFirmware = false;
  bool get hasNewFirmware => _hasNewFirmware;

  String _newFirmwareVersion = '';
  String get newFirmwareVersion => _newFirmwareVersion;

  bool get isNetworkGood => true;

  int _savedCalibrationWeight = 5000;
  int get savedCalibrationWeight => _savedCalibrationWeight;

  final List<String> _autoModeOptions = ['1', '2', '3', '4', '5'];
  List<String> get autoModeOptions => _autoModeOptions;

  int get autoModeIndex {
    if (_currentDevice == null) return 0;
    int mins = _currentDevice!.autoModeDelaySeconds ~/ 60;
    int idx = _autoModeOptions.indexOf(mins.toString());
    return idx == -1 ? 0 : idx;
  }

  Timer? _otaPollingTimer;
  bool _isOtaUpdating = false;
  bool get isOtaUpdating => _isOtaUpdating;

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
      setError('offline');
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
    required String errorMsg,
  }) async {
    _currentDevice!.updateAttributesFromMap(newAttrs);
    notifyListeners();

    final success = await _executeWithTimeout(apiCall);
    if (!success) {
      _currentDevice!.updateAttributesFromMap(oldAttrs);
      setError(errorMsg);
      notifyListeners();
    }
  }

  Future<void> selectDevice(String id) async {
    if (_currentDevice?.deviceId == id) return;
    _currentDevice = _deviceRepo.getDevice(id);
    _localTimerList = List.from(_currentDevice!.timerList);

    try {
      final prefs = await SharedPreferences.getInstance();
      _savedCalibrationWeight = prefs.getInt('calibration_weight_$id') ?? 5000;
      _currentTimeZoneId = await FlutterTimezone.getLocalTimezone();
      _currentTimeZoneOffset = _calculateOffsetStr(_currentTimeZoneId);
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
        _hasNewFirmware = true;
        _newFirmwareVersion = otaData['version']?.toString() ?? '最新版';
        _pendingOtaRecordId = otaData['recordId'].toString();
      } else {
        _hasNewFirmware = false;
        _newFirmwareVersion = '';
        _pendingOtaRecordId = '';
      }
    } catch (e) {
      setError(e.toString());
    } finally {
      if (needsLoading) setLoading(false);
      notifyListeners();
    }
  }

  Future<void> setMode(WorkMode mode) async {
    if (!_checkOffline()) return;
    if (_currentDevice!.workMode == mode) return;

    if (mode == WorkMode.timer || mode == WorkMode.manual) {
      if (_currentDevice!.isDndEnabled) {
        toggleDnd(false);
      }
    }

    final previousMode = _currentDevice!.workMode;
    final attrs = <Map<String, dynamic>>[
      {'dpid': DeviceThingModel.deviceMode.dpid, 'value': mode.value.toString()},
    ];
    if (mode == WorkMode.timer) {
      attrs.add({'dpid': DeviceThingModel.timerModeSchedule.dpid, 'value': '["0","28800"]'});
    }

    await _executeOptimistic(
      newAttrs: {DeviceThingModel.deviceMode.dpid: mode.value.toString()},
      oldAttrs: {DeviceThingModel.deviceMode.dpid: previousMode.value.toString()},
      apiCall: () => _deviceRepo.sendDeviceCommand(_currentDevice!.deviceId, attrs),
      errorMsg: 'Failed to set mode',
    );
  }

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
      errorMsg: 'Failed to toggle DND',
    );
  }

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
      errorMsg: 'Failed to execute action',
    );
  }

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
      errorMsg: 'Failed to toggle child lock',
    );
  }

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
      errorMsg: 'Failed to toggle plasma',
    );
  }

  void updateAutoMode(int index) async {
    if (!_checkOffline()) return;
    int minutes = int.parse(_autoModeOptions[index]);
    int seconds = minutes * 60;

    final previousSeconds = _currentDevice!.autoModeDelaySeconds;

    await _executeOptimistic(
      newAttrs: {DeviceThingModel.autoModeDelay.dpid: seconds.toString()},
      oldAttrs: {DeviceThingModel.autoModeDelay.dpid: previousSeconds.toString()},
      apiCall: () => _deviceRepo.sendDeviceCommand(_currentDevice!.deviceId, [
        {'dpid': DeviceThingModel.autoModeDelay.dpid, 'value': seconds.toString()},
      ]),
      errorMsg: 'Failed to update auto mode',
    );
  }

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
      errorMsg: 'Failed to set DND time',
    );
  }

  void setTimeZone(String tzId, String offsetStr) {
    _currentTimeZoneId = tzId;
    _currentTimeZoneOffset = offsetStr;
    notifyListeners();
  }

  void addTimer(String timeStr) {
    _localTimerList.add(timeStr);
    _localTimerList.sort();
    notifyListeners();
  }

  void removeTimer(int index) {
    _localTimerList.removeAt(index);
    notifyListeners();
  }

  Future<void> submitTimers() async {
    if (!_checkOffline()) return;
    setLoading(true);
    final secondsArray = _localTimerList.map((time) => _timeToSeconds(time)).toList();
    final timersJsonString = jsonEncode(secondsArray.map((e) => e.toString()).toList());
    final success = await _executeWithTimeout(
      () => _deviceRepo.sendDeviceCommand(_currentDevice!.deviceId, [
        {'dpid': DeviceThingModel.timerModeSchedule.dpid, 'value': timersJsonString},
      ]),
    );
    setLoading(false);
    if (!success) setError('Failed to save timers');
  }

  Future<bool> startCalibrationStep1() async {
    if (!_checkOffline()) return false;
    setLoading(true);
    final success = await _executeWithTimeout(
      () => _deviceRepo.sendDeviceCommand(_currentDevice!.deviceId, [
        {'dpid': DeviceThingModel.prepareCalibration.dpid, 'value': true},
      ]),
    );
    setLoading(false);
    if (!success) setError('Calibration start failed');
    return success;
  }

  Future<bool> submitCalibrationStep3(int weightGrams) async {
    if (!_checkOffline()) return false;
    setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('calibration_weight_${_currentDevice!.deviceId}', weightGrams);
      _savedCalibrationWeight = weightGrams;
    } catch (_) {}

    final success = await _executeWithTimeout(
      () => _deviceRepo.sendDeviceCommand(_currentDevice!.deviceId, [
        {'dpid': DeviceThingModel.calibrationWeight.dpid, 'value': weightGrams},
        {'dpid': DeviceThingModel.calibration.dpid, 'value': true},
      ]),
    );
    setLoading(false);
    if (!success) setError('Calibration submit failed');
    return success;
  }

  Future<void> resetWifi() async {
    if (!_checkOffline()) return;
    setLoading(true);
    final success = await _executeWithTimeout(
      () => _deviceRepo.sendDeviceCommand(_currentDevice!.deviceId, [
        {'dpid': DeviceThingModel.resetWlan.dpid, 'value': true},
      ]),
    );
    setLoading(false);
    if (!success) setError('Failed to reset Wi-Fi');
  }

  Future<bool> startFirmwareUpgrade({int timeoutSeconds = 120}) async {
    if (!_checkOffline()) return false;
    if (_pendingOtaRecordId.isEmpty) {
      setError('No pending firmware');
      return false;
    }

    setLoading(true);
    final targetVersion = _newFirmwareVersion;
    final success = await _deviceRepo.dispatchFirmwareUpgrade(_currentDevice!.deviceId, _pendingOtaRecordId);
    setLoading(false);

    if (success) {
      _hasNewFirmware = false;
      _isOtaUpdating = true;
      notifyListeners();
      _startOtaPolling(_currentDevice!.deviceId, targetVersion, timeoutSeconds);
      return true;
    } else {
      setError('Dispatch firmware failed');
      return false;
    }
  }

  void _startOtaPolling(String deviceId, String targetVersion, int timeoutSeconds) {
    _otaPollingTimer?.cancel();
    final startTime = DateTime.now();

    _otaPollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (DateTime.now().difference(startTime).inSeconds >= timeoutSeconds) {
        stopOtaPolling();
        setError('OTA timeout');
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
    _isOtaUpdating = false;
  }

  Future<bool> updateDeviceName(String newName) async {
    if (_currentDevice == null) return false;
    setLoading(true);
    final success = await _deviceRepo.renameDevice(_currentDevice!.deviceId, newName);
    setLoading(false);
    if (!success) setError('Failed to rename');
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
