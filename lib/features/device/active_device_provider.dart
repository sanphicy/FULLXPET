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
  // 设备数据仓库实例
  final DeviceRepository _deviceRepo = locator<DeviceRepository>();

  // 当前选中的设备对象
  DeviceDto? _currentDevice;
  DeviceDto? get currentDevice => _currentDevice;

  // 设备更新事件订阅
  StreamSubscription<String>? _repoSubscription;

  // 暂存 OTA 记录 ID
  String _pendingOtaRecordId = '';
  // 当前设备时区标识（如：Asia/Shanghai）
  String _currentTimeZoneId = 'Asia/Shanghai';
  String get currentTimeZoneId => _currentTimeZoneId;

  // 当前设备时区偏移量字符串（如：UTC+08:00）
  String _currentTimeZoneOffset = 'UTC+08:00';
  String get currentTimeZoneOffset => _currentTimeZoneOffset;

  // 本地定时任务时间列表（格式："HH:mm"）
  List<String> _localTimerList = [];

  // 获取定时任务时间列表
  List<String> get timerList => _localTimerList;

  // 是否有新固件可供升级
  bool _hasNewFirmware = false;
  bool get hasNewFirmware => _hasNewFirmware;

  // 新固件版本号
  String _newFirmwareVersion = '';
  String get newFirmwareVersion => _newFirmwareVersion;

  // 获取网络状态是否良好
  bool get isNetworkGood => true;

  // 本地保存的校准砝码重量（单位：克）
  int _savedCalibrationWeight = 5000;
  int get savedCalibrationWeight => _savedCalibrationWeight;

  // 自动模式延迟时间选项列表（单位：分钟）
  final List<String> _autoModeOptions = ['1', '2', '3', '4', '5'];
  List<String> get autoModeOptions => _autoModeOptions;

  int get autoModeIndex {
    if (_currentDevice == null) return 0;
    int mins = _currentDevice!.autoModeDelaySeconds ~/ 60;
    int idx = _autoModeOptions.indexOf(mins.toString());
    return idx == -1 ? 0 : idx;
  }

  // ================= OTA 纯轮询状态变量 =================
  Timer? _otaPollingTimer;
  bool _isOtaUpdating = false;
  bool get isOtaUpdating => _isOtaUpdating;
  // ====================================================

  // 构造函数，监听设备仓库数据更新与应用生命周期
  ActiveDeviceProvider() {
    _repoSubscription = _deviceRepo.onDeviceUpdated.listen((updatedDeviceId) {
      if (_currentDevice != null && _currentDevice!.deviceId == updatedDeviceId) {
        notifyListeners();
      }
    });
    // 注册生命周期监听
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

    if (state == AppLifecycleState.resumed) {
      if (_currentDevice != null) {
        _deviceRepo.fetchDeviceProperties(_currentDevice!.deviceId).then((_) {
          notifyListeners();
        });
      }
    }
  }

  bool _checkOffline() {
    if (_currentDevice == null) return false;
    if (!_currentDevice!.isOnline) {
      setError("设备离线无法操作");
      return false;
    }
    return true;
  }

  Future<bool> _executeWithTimeout(Future<bool> Function() action) async {
    try {
      return await action().timeout(const Duration(seconds: 3));
    } catch (e) {
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

  // 选择并切换当前操作的设备
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
    final needsLoading = _currentDevice!.wifiMac == "00:00:00:00:00:00";
    if (needsLoading) setLoading(true);
    try {
      await _deviceRepo.fetchDeviceProperties(id);
      await _deviceRepo.fetchDeviceLogs(id, isLoadMore: false);

      // 主动检查设备是否有待升级的固件
      final otaData = await _deviceRepo.checkPendingFirmware(id);

      if (otaData != null && otaData['recordId'] != null) {
        _hasNewFirmware = true;
        _newFirmwareVersion = otaData['version']?.toString() ?? '最新版';
        _pendingOtaRecordId = otaData['recordId'].toString();
        debugPrint("✅ 匹配到固件升级! 版本: $_newFirmwareVersion, RecordID: $_pendingOtaRecordId");
      } else {
        _hasNewFirmware = false;
        _newFirmwareVersion = '';
        _pendingOtaRecordId = '';
      }
    } catch (e) {
      setError("Sync Error: $e");
    } finally {
      if (needsLoading) setLoading(false);
      notifyListeners();
    }
  }

  // 设置设备工作模式（自动/定时/手动等）
  Future<void> setMode(WorkMode mode) async {
    if (!_checkOffline()) return;
    if (_currentDevice!.workMode == mode) return;

    if (mode == WorkMode.timer || mode == WorkMode.manual) {
      if (_currentDevice!.isDndEnabled) {
        toggleDnd(false);
      }
    }

    final previousMode = _currentDevice!.workMode;
    await _executeOptimistic(
      newAttrs: {DeviceThingModel.deviceMode.dpid: mode.value.toString()},
      oldAttrs: {DeviceThingModel.deviceMode.dpid: previousMode.value.toString()},
      apiCall: () => _deviceRepo.setWorkMode(_currentDevice!.deviceId, mode),
      errorMsg: "Failed to set mode",
    );
  }

  // 切换免打扰模式开关
  Future<void> toggleDnd(bool isBool) async {
    if (!_checkOffline()) return;

    final previousState = _currentDevice!.isDndEnabled;
    final targetState = !previousState;

    if (!isBool && (_currentDevice!.workMode != WorkMode.auto)) {
      setMode(WorkMode.auto);
    }

    await _executeOptimistic(
      newAttrs: {DeviceThingModel.notdisturbModeStatus.dpid: targetState},
      oldAttrs: {DeviceThingModel.notdisturbModeSchedule.dpid: previousState},
      apiCall: () => _deviceRepo.setDndStatus(_currentDevice!.deviceId, targetState),
      errorMsg: "Failed to toggle Do Not Disturb",
    );
  }

  // 执行设备指定动作（如清理、抚平等）
  Future<void> executeAction(ExecuteAction action) async {
    if (!_checkOffline()) return;

    final previousAction = _currentDevice!.executeAction;
    await _executeOptimistic(
      newAttrs: {DeviceThingModel.deviceExecute.dpid: action.value.toString()},
      oldAttrs: {DeviceThingModel.deviceExecute.dpid: previousAction.value.toString()},
      apiCall: () => _deviceRepo.executeAction(_currentDevice!.deviceId, action),
      errorMsg: "Failed to execute action",
    );
  }

  // 切换童锁功能开关
  Future<void> toggleChildLock() async {
    if (!_checkOffline()) return;

    final previousState = _currentDevice!.isChildLockEnabled;
    final targetState = !previousState;

    await _executeOptimistic(
      newAttrs: {DeviceThingModel.childLockSwitch.dpid: targetState},
      oldAttrs: {DeviceThingModel.childLockSwitch.dpid: previousState},
      apiCall: () => _deviceRepo.setChildLock(_currentDevice!.deviceId, targetState),
      errorMsg: "Failed to toggle child lock",
    );
  }

  // 等离子状态
  Future<void> togglePlasma() async {
    if (!_checkOffline()) return;

    final previousState = _currentDevice!.isPlasmaEnabled;
    final targetState = !previousState;

    await _executeOptimistic(
      newAttrs: {DeviceThingModel.palsmaState.dpid: targetState},
      oldAttrs: {DeviceThingModel.palsmaState.dpid: previousState},
      apiCall: () => _deviceRepo.setPlasmaState(_currentDevice!.deviceId, targetState),
      errorMsg: "Failed to toggle plasma",
    );
  }

  // 更新自动模式下的延迟等待时长
  void updateAutoMode(int index) async {
    if (!_checkOffline()) return;
    int minutes = int.parse(_autoModeOptions[index]);
    int seconds = minutes * 60;

    final previousSeconds = _currentDevice!.autoModeDelaySeconds;

    await _executeOptimistic(
      newAttrs: {DeviceThingModel.autoModeDelay.dpid: seconds.toString()},
      oldAttrs: {DeviceThingModel.autoModeDelay.dpid: previousSeconds.toString()},
      apiCall: () => _deviceRepo.setAutoModeDelay(_currentDevice!.deviceId, seconds),
      errorMsg: "Failed to update auto mode",
    );
  }

  // 设置免打扰模式的时间段范围
  void setDndTime(String start, String end) async {
    if (!_checkOffline()) return;

    int startSec = _timeToSeconds(start);
    int endSec = _timeToSeconds(end);

    final previousRange = _currentDevice!.dndTimeRange;
    final oldStartSec = _timeToSeconds(previousRange['start']!);
    final oldEndSec = _timeToSeconds(previousRange['end']!);

    final newJsonStr = jsonEncode({"TimerStart": startSec.toString(), "TimerEnd": endSec.toString()});
    final oldJsonStr = jsonEncode({"TimerStart": oldStartSec.toString(), "TimerEnd": oldEndSec.toString()});

    await _executeOptimistic(
      newAttrs: {DeviceThingModel.notdisturbModeSchedule.dpid: newJsonStr},
      oldAttrs: {DeviceThingModel.notdisturbModeSchedule.dpid: oldJsonStr},
      apiCall: () => _deviceRepo.setDndTimeRange(_currentDevice!.deviceId, startSec, endSec),
      errorMsg: "Failed to set DND time",
    );
  }

  // 更新本地设置的时区信息
  void setTimeZone(String tzId, String offsetStr) {
    _currentTimeZoneId = tzId;
    _currentTimeZoneOffset = offsetStr;
    notifyListeners();
  }

  // 在本地定时列表中添加一个新的定时时间
  void addTimer(String timeStr) {
    _localTimerList.add(timeStr);
    _localTimerList.sort();
    notifyListeners();
  }

  // 从本地定时列表中移除指定索引的定时
  void removeTimer(int index) {
    _localTimerList.removeAt(index);
    notifyListeners();
  }

  // 提交并保存本地定时任务列表到云端/设备
  Future<void> submitTimers() async {
    if (!_checkOffline()) return;
    setLoading(true);
    final secondsArray = _localTimerList.map((time) => _timeToSeconds(time)).toList();
    final success = await _executeWithTimeout(() => _deviceRepo.submitTimers(_currentDevice!.deviceId, secondsArray));
    if (success) {
      showSuccessToast("Success");
    } else {
      setError("Error");
    }
    setLoading(false);
  }

  // 开始称重校准 (第一步)
  Future<bool> startCalibrationStep1() async {
    if (!_checkOffline()) return false;
    setLoading(true);
    final success = await _executeWithTimeout(() => _deviceRepo.startCalibrationStep1(_currentDevice!.deviceId));
    setLoading(false);
    if (!success) setError("Failed");
    return success;
  }

  // 提交称重校准 (第三步)
  Future<bool> submitCalibrationStep3(int weightGrams) async {
    if (!_checkOffline()) return false;
    setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('calibration_weight_${_currentDevice!.deviceId}', weightGrams);
      _savedCalibrationWeight = weightGrams;
    } catch (_) {}
    final success = await _executeWithTimeout(
      () => _deviceRepo.submitCalibrationStep3(_currentDevice!.deviceId, weightGrams),
    );
    setLoading(false);
    if (!success) setError("Failed");
    return success;
  }

  // 发送重置 Wi-Fi 指令
  Future<void> resetWifi() async {
    if (!_checkOffline()) return;
    setLoading(true);
    final success = await _executeWithTimeout(() => _deviceRepo.resetWifi(_currentDevice!.deviceId));
    setLoading(false);
    if (success) {
      showSuccessToast("Reset Wi-Fi command sent");
    } else {
      setError("Failed to reset Wi-Fi");
    }
  }

  // ==================== 最简 OTA 短轮询逻辑 ====================

  /// 启动 OTA 升级并开启纯轮询
  Future<bool> startFirmwareUpgrade({int timeoutSeconds = 120}) async {
    if (!_checkOffline()) return false;
    if (_pendingOtaRecordId.isEmpty) {
      setError("没有可升级的固件");
      return false;
    }

    setLoading(true);
    final targetVersion = _newFirmwareVersion; // 目标版本号
    final success = await _deviceRepo.dispatchFirmwareUpgrade(_currentDevice!.deviceId, _pendingOtaRecordId);
    setLoading(false);

    if (success) {
      _hasNewFirmware = false;
      _isOtaUpdating = true;
      notifyListeners();

      // 开始纯短轮询检测版本号
      _startOtaPolling(_currentDevice!.deviceId, targetVersion, timeoutSeconds);
      return true;
    } else {
      setError("下发固件升级指令失败");
      return false;
    }
  }

  /// 纯短轮询：每 3 秒检测一次 fetchDeviceProperties
  void _startOtaPolling(String deviceId, String targetVersion, int timeoutSeconds) {
    _otaPollingTimer?.cancel();
    final startTime = DateTime.now();

    _otaPollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      // 1. 检查超时
      if (DateTime.now().difference(startTime).inSeconds >= timeoutSeconds) {
        stopOtaPolling();
        setError("OTA 升级超时，请检查设备状态");
        notifyListeners();
        return;
      }

      try {
        // 2. 拉取最新物模型属性
        await _deviceRepo.fetchDeviceProperties(deviceId);

        // 3. 判断版本号是否升级成功
        if (_currentDevice != null && _currentDevice!.firmwareVersion == targetVersion) {
          stopOtaPolling();
          showSuccessToast("固件升级完成！");
          notifyListeners();
        }
      } catch (e) {
        debugPrint("OTA 轮询异常: $e");
      }
    });
  }

  /// 停止 OTA 轮询
  void stopOtaPolling() {
    _otaPollingTimer?.cancel();
    _otaPollingTimer = null;
    _isOtaUpdating = false;
  }

  // ===========================================================

  // 修改设备名称
  Future<bool> updateDeviceName(String newName) async {
    if (_currentDevice == null) return false;
    setLoading(true);
    final success = await _deviceRepo.renameDevice(_currentDevice!.deviceId, newName);
    setLoading(false);
    if (success) {
      showSuccessToast("Name updated");
      return true;
    } else {
      setError("Failed to update name");
      return false;
    }
  }

  // 显示操作成功的应用 Toast 提示
  void showSuccessToast(String message) {
    NavService.rootNavigatorKey.currentContext?.showAppToast(message: message, type: AppToastType.success);
  }

  // 将 "HH:mm" 格式的时间字符串转为一天内的总秒数
  int _timeToSeconds(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 3600 + m * 60;
  }

  // 根据时区名称计算格式化的时区偏移量字符串
  String _calculateOffsetStr(String tzName) {
    try {
      final location = tz.getLocation(tzName);
      final offset = tz.TZDateTime.now(location).timeZoneOffset;
      final hours = offset.inHours;
      final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
      final sign = hours >= 0 ? '+' : '-';
      return 'UTC$sign${hours.abs().toString().padLeft(2, '0')}:$minutes';
    } catch (e) {
      return 'UTC+00:00';
    }
  }
}
