import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/core/network/api_exception.dart';
import 'package:fullxpet/core/utils/device_batch_helper.dart';
import 'package:fullxpet/core/utils/time_utils.dart';
import 'package:fullxpet/features/device/models/device_hardware_info.dart';
import 'package:fullxpet/features/device/models/device_item_dto.dart';
import 'package:fullxpet/features/device/models/product_dto.dart';
import 'package:fullxpet/features/device/models/feeder_live_info.dart';
import 'package:fullxpet/features/device/products/feeder/models/feeder_thing_model.dart';
import 'package:fullxpet/features/device/repositories/device_repository.dart';
import 'package:fullxpet/locator.dart';

/// 定时区间实体
class FeederTimeRange {
  final String start;
  final String end;

  FeederTimeRange({required this.start, required this.end});

  int get startSeconds => TimeUtils.timeToSeconds(start);
  int get endSeconds => TimeUtils.timeToSeconds(end);
}

class FeederViewModel extends BaseProvider with WidgetsBindingObserver {
  final DeviceRepository _deviceRepo = locator.get();

  String _deviceId = '';
  String get deviceId => _deviceId;

  /// 乐观更新覆盖层
  final DpidValueMap _optimisticOverrides = {};

  FeederLiveInfo? _liveInfo;
  FeederLiveInfo? get liveInfo => _liveInfo;

  bool _isLiveLoading = true;
  bool get isLiveLoading => _isLiveLoading;

  String _liveErrorMsg = '';
  String get liveErrorMsg => _liveErrorMsg;

  // --- OTA 升级相关状态 ---
  bool _hasNewFirmware = false;
  String _newFirmwareVersion = '';
  String _pendingOtaRecordId = '';
  bool _isOtaUpdating = false;
  Timer? _otaPollingTimer;

  bool get hasNewFirmware => _hasNewFirmware;
  String get newFirmwareVersion => _newFirmwareVersion;
  bool get isOtaUpdating => _isOtaUpdating;

  StreamSubscription? _repoSub;

  FeederViewModel() {
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

  // ================= 1. 从底表 1、底表 2、硬件表读取基础信息 =================

  DeviceItemDto? get basicInfo => _deviceRepo.getDeviceBasic(_deviceId);

  ProductDto? get productInfo {
    final pid = basicInfo?.productId ?? '';
    return _deviceRepo.getProduct(pid);
  }

  DeviceHardwareInfo get hardwareInfo => _deviceRepo.getDeviceHardwareInfo(_deviceId);

  String get deviceName => basicInfo?.nickname.isNotEmpty == true ? basicInfo!.nickname : 'PETLUX AI Feeder';

  String get productName => productInfo?.name ?? '';

  String get displayId => DeviceBatchHelper().getDisplayBatchNo(_deviceId);

  bool get isOnline => basicInfo?.online ?? false;

  /// 设备网络图片（优先取设备 iconUrl，其次取产品表 thumbnailUrl）
  String get imageUrl {
    final icon = basicInfo?.iconUrl ?? '';
    if (icon.isNotEmpty) return icon;
    return productInfo?.thumbnailUrl ?? '';
  }

  // ================= 2. 从底表 3 (_deviceDpidCache) 读取实时物模型属性 =================

  dynamic _getDpid(FeederThingModel model) {
    if (_optimisticOverrides.containsKey(model.dpid)) {
      return _optimisticOverrides[model.dpid];
    }
    return _deviceRepo.getDpidValue(_deviceId, model.dpid);
  }

  /// 当前工作模式（优先根据各模式布尔 DP 判断，兜底使用 deviceMode）
  FeederMode get currentMode {
    final autoVal = _getDpid(FeederThingModel.autoMode);
    if (autoVal == true || autoVal?.toString() == 'true') {
      return FeederMode.faceAi;
    }
    final semiVal = _getDpid(FeederThingModel.semiautomode);
    if (semiVal == true || semiVal?.toString() == 'true') {
      return FeederMode.infrared;
    }
    final openVal = _getDpid(FeederThingModel.gapingMode);
    if (openVal == true || openVal?.toString() == 'true') {
      return FeederMode.open;
    }
    final modeRaw = _getDpid(FeederThingModel.deviceMode);
    if (modeRaw != null) {
      final int modeVal = int.tryParse(modeRaw.toString()) ?? 2;
      return FeederMode.fromValue(modeVal);
    }
    return FeederMode.open;
  }

  /// 定时模式是否已开启 (DP 3)
  bool get isTimerEnabled {
    final val = _getDpid(FeederThingModel.delayMode);
    return val == true || val?.toString() == 'true';
  }

  /// 推杆限位状态 (DP 9)
  bool get isDoorDispensed {
    final val = _getDpid(FeederThingModel.gapingState);
    return val == true || val?.toString() == 'true';
  }

  /// 童锁开关 (DP 6)
  bool get isChildLock {
    final val = _getDpid(FeederThingModel.childLockSwitch);
    return val == true || val?.toString() == 'true';
  }

  int get deviceStatus {
    final val = _getDpid(FeederThingModel.deviceStatus);
    return int.tryParse(val?.toString() ?? '') ?? 0;
  }

  // --- 优先从硬件表读取固件版本与 Wi-Fi 信息，回退读取 DP 属性 ---
  String get firmwareVersion {
    if (hardwareInfo.mcuVersion.isNotEmpty) return hardwareInfo.mcuVersion;
    if (hardwareInfo.wifiVersion.isNotEmpty) return hardwareInfo.wifiVersion;
    return '';
  }

  String get wifiSsid {
    if (hardwareInfo.ssid.isNotEmpty) return hardwareInfo.ssid;
    return _getDpid(FeederThingModel.deviceSsid)?.toString() ?? '';
  }

  String get wifiRssi {
    final dpVal = _getDpid(FeederThingModel.deviceRssi)?.toString() ?? '';
    if (dpVal.isNotEmpty && dpVal != '0') {
      return dpVal.endsWith('dBm') ? dpVal : '${dpVal}dBm';
    }
    final hwRssi = hardwareInfo.rssi.trim();
    if (hwRssi.isNotEmpty && hwRssi != '0') {
      return hwRssi.endsWith('dBm') ? hwRssi : '${hwRssi}dBm';
    }
    return '-';
  }

  String get wifiChannel => hardwareInfo.channel.isNotEmpty ? hardwareInfo.channel : '-';
  String get hardwareAddress {
    if (basicInfo != null && basicInfo!.hardwareId.isNotEmpty) {
      return basicInfo!.hardwareId;
    }
    if (hardwareInfo.imei.isNotEmpty) return hardwareInfo.imei;
    return '-';
  }

  /// 单一时间段解析：{"TimerStart":"...","TimerEnd":"..."} (DP 15)
  FeederTimeRange? get singleTimerRange {
    final val = _getDpid(FeederThingModel.timerModeSchedule);
    if (val == null || val.toString().isEmpty) return null;
    try {
      final Map rawMap = jsonDecode(val.toString()) as Map;
      if (rawMap.containsKey('TimerStart') && rawMap.containsKey('TimerEnd')) {
        final startSec = int.tryParse(rawMap['TimerStart'].toString()) ?? 0;
        final endSec = int.tryParse(rawMap['TimerEnd'].toString()) ?? 0;
        return FeederTimeRange(start: TimeUtils.secondsToTime(startSec), end: TimeUtils.secondsToTime(endSec));
      }
    } catch (_) {}
    return null;
  }

  // ================= 3. 初始化与控制指令下发 =================

  Future<void> initDevice(String id) async {
    _deviceId = id;
    _optimisticOverrides.clear();
    clearError();
    notifyListeners();

    unawaited(fetchLiveStreamInfo());

    final bool hasCache = _deviceRepo.getDeviceDpidMap(id).isNotEmpty;
    if (!hasCache) setLoading(true);

    try {
      await Future.wait([_deviceRepo.fetchDeviceProperties(id), checkFirmwareUpdate()]);
    } catch (e) {
      setError(e.toString());
    } finally {
      if (isLoading) setLoading(false);
      notifyListeners();
    }
  }

  Future<bool> _executeOptimistic({
    required DpidValueMap optimisticChanges,
    required CommandAttrList commandPayload,
    required String errorMsg,
  }) async {
    final Map prev = Map.from(_optimisticOverrides);
    optimisticChanges.forEach((k, v) => _optimisticOverrides[k] = v);
    notifyListeners();

    bool success = false;
    try {
      success = await _deviceRepo.sendDeviceCommand(_deviceId, commandPayload).timeout(const Duration(seconds: 3));
    } catch (_) {
      success = false;
    }

    if (!success) {
      _optimisticOverrides
        ..clear()
        ..addAll(prev.cast());
      await _deviceRepo.fetchDeviceProperties(_deviceId);
      setError(errorMsg);
      notifyListeners();
    }
    return success;
  }

  /// 切换模式（敞开 / 红外(半自动) / 猫脸识别(自动)），同时将其他模式（含定时）置为 false
  Future<void> switchMode(FeederMode mode) async {
    if (_deviceId.isEmpty) return;
    if (currentMode == mode && !isTimerEnabled) return;

    final bool isAuto = mode == FeederMode.faceAi;
    final bool isOpen = mode == FeederMode.open;
    final bool isSemiAuto = mode == FeederMode.infrared;

    final CommandAttrList commandPayload = [
      {'dpid': FeederThingModel.autoMode.dpid, 'type': 1, 'value': isAuto},
      {'dpid': FeederThingModel.delayMode.dpid, 'type': 1, 'value': false},
      {'dpid': FeederThingModel.gapingMode.dpid, 'type': 1, 'value': isOpen},
      {'dpid': FeederThingModel.semiautomode.dpid, 'type': 1, 'value': isSemiAuto},
    ];

    await _executeOptimistic(
      optimisticChanges: {
        FeederThingModel.autoMode.dpid: isAuto,
        FeederThingModel.delayMode.dpid: false,
        FeederThingModel.gapingMode.dpid: isOpen,
        FeederThingModel.semiautomode.dpid: isSemiAuto,
        FeederThingModel.deviceMode.dpid: mode.value,
      },
      commandPayload: commandPayload,
      errorMsg: '切换模式失败，请检查设备在线状态',
    );
  }

  /// 开启定时模式：同时将定时(delayMode)与敞开(gapingMode)设为 true，自动与半自动设为 false
  Future<bool> enableTimerWithOpenMode() async {
    if (_deviceId.isEmpty) return false;

    final CommandAttrList commandPayload = [
      {'dpid': FeederThingModel.autoMode.dpid, 'type': 1, 'value': false},
      {'dpid': FeederThingModel.delayMode.dpid, 'type': 1, 'value': true},
      {'dpid': FeederThingModel.gapingMode.dpid, 'type': 1, 'value': true},
      {'dpid': FeederThingModel.semiautomode.dpid, 'type': 1, 'value': false},
    ];

    return await _executeOptimistic(
      optimisticChanges: {
        FeederThingModel.autoMode.dpid: false,
        FeederThingModel.delayMode.dpid: true,
        FeederThingModel.gapingMode.dpid: true,
        FeederThingModel.semiautomode.dpid: false,
        FeederThingModel.deviceMode.dpid: FeederMode.open.value,
      },
      commandPayload: commandPayload,
      errorMsg: '开启定时模式失败，请检查设备在线状态',
    );
  }

  /// 关闭定时模式
  Future<bool> disableTimerMode() async {
    if (_deviceId.isEmpty) return false;

    return await _executeOptimistic(
      optimisticChanges: {FeederThingModel.delayMode.dpid: false},
      commandPayload: [
        {'dpid': FeederThingModel.delayMode.dpid, 'type': 1, 'value': false},
      ],
      errorMsg: '关闭定时模式失败',
    );
  }

  /// 敞开模式下手动控制出粮推杆开关 (DP 9)
  Future<void> toggleFeedSwitch() async {
    if (_deviceId.isEmpty || currentMode != FeederMode.open) return;
    final targetState = !isDoorDispensed;

    await _executeOptimistic(
      optimisticChanges: {FeederThingModel.gapingState.dpid: targetState},
      commandPayload: [
        {'dpid': FeederThingModel.gapingState.dpid, 'value': targetState},
      ],
      errorMsg: '控制推杆失败',
    );
  }

  /// 切换童锁 (DP 6)
  Future<void> toggleChildLock() async {
    if (_deviceId.isEmpty) return;
    final targetState = !isChildLock;

    await _executeOptimistic(
      optimisticChanges: {FeederThingModel.childLockSwitch.dpid: targetState},
      commandPayload: [
        {'dpid': FeederThingModel.childLockSwitch.dpid, 'type': 1, 'value': targetState},
      ],
      errorMsg: '设置童锁失败',
    );
  }

  /// 单次定时范围设置 (DP 15)
  Future<bool> setSingleTimerRange(String start, String end) async {
    if (_deviceId.isEmpty) return false;

    final startSec = TimeUtils.timeToSeconds(start);
    final endSec = TimeUtils.timeToSeconds(end);
    final jsonStr = jsonEncode({'TimerStart': startSec.toString(), 'TimerEnd': endSec.toString()});

    return await _executeOptimistic(
      optimisticChanges: {FeederThingModel.timerModeSchedule.dpid: jsonStr},
      commandPayload: [
        {'dpid': FeederThingModel.timerModeSchedule.dpid, 'type': 3, 'value': jsonStr},
      ],
      errorMsg: '设置定时时间段失败',
    );
  }

  /// 清空定时范围 (DP 15)
  Future<bool> removeTimerRange() async {
    if (_deviceId.isEmpty) return false;
    const jsonStr = '';

    return await _executeOptimistic(
      optimisticChanges: {FeederThingModel.timerModeSchedule.dpid: jsonStr},
      commandPayload: [
        {'dpid': FeederThingModel.timerModeSchedule.dpid, 'type': 3, 'value': jsonStr},
      ],
      errorMsg: '清空定时失败',
    );
  }

  /// 重置设备网络 (DP 1)
  Future<bool> resetWifi() async {
    if (_deviceId.isEmpty) return false;
    return await _deviceRepo.sendDeviceCommand(_deviceId, [
      {'dpid': FeederThingModel.resetWlan.dpid, 'value': true},
    ]);
  }

  // ================= 4. 直播流、OTA、改名、解绑删除 =================

  Future<void> fetchLiveStreamInfo({int camera = 0, int resolution = 0, int retryCount = 1}) async {
    if (_deviceId.isEmpty) return;
    _isLiveLoading = true;
    _liveErrorMsg = '';
    notifyListeners();

    try {
      final info = await _deviceRepo.fetchLiveInfo(_deviceId, camera: camera, resolution: resolution);
      if (info.isValid) {
        _liveInfo = info;
        _isLiveLoading = false;
        notifyListeners();
        return;
      }
      if (retryCount > 0) {
        await Future.delayed(const Duration(milliseconds: 800));
        await fetchLiveStreamInfo(camera: camera, resolution: resolution, retryCount: retryCount - 1);
      } else {
        _isLiveLoading = false;
        _liveErrorMsg = '获取直播参数失败';
        notifyListeners();
      }
    } catch (e) {
      if (retryCount > 0) {
        await Future.delayed(const Duration(milliseconds: 800));
        await fetchLiveStreamInfo(camera: camera, resolution: resolution, retryCount: retryCount - 1);
      } else {
        _isLiveLoading = false;
        _liveErrorMsg = ApiException.from(e).message;
        notifyListeners();
      }
    }
  }

  Future<void> checkFirmwareUpdate() async {
    if (_deviceId.isEmpty) return;
    try {
      final otaData = await _deviceRepo.checkPendingFirmware(_deviceId);
      if (otaData != null && otaData['recordId'] != null) {
        _hasNewFirmware = true;
        _newFirmwareVersion = otaData['version']?.toString() ?? '最新';
        _pendingOtaRecordId = otaData['recordId'].toString();
      } else {
        _hasNewFirmware = false;
        _newFirmwareVersion = '';
        _pendingOtaRecordId = '';
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> startFirmwareUpgrade({int timeoutSeconds = 120}) async {
    if (_deviceId.isEmpty || _pendingOtaRecordId.isEmpty) {
      setError('没有要升级的固件');
      return false;
    }

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
      setError('下发固件升级失败');
      return false;
    }
  }

  void _startOtaPolling(String id, String targetVersion, int timeoutSeconds) {
    _otaPollingTimer?.cancel();
    final startTime = DateTime.now();

    _otaPollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (DateTime.now().difference(startTime).inSeconds >= timeoutSeconds) {
        stopOtaPolling();
        setError('OTA 升级超时');
        notifyListeners();
        return;
      }
      try {
        await _deviceRepo.fetchDeviceProperties(id);
        if (firmwareVersion == targetVersion) {
          stopOtaPolling();
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Feeder OTA Polling Exception: $e');
      }
    });
  }

  void stopOtaPolling() {
    _otaPollingTimer?.cancel();
    _otaPollingTimer = null;
    _isOtaUpdating = false;
  }

  /// 重命名设备（直接更新底表 2）
  Future<bool> updateDeviceName(String newName) async {
    if (_deviceId.isEmpty) return false;
    setLoading(true);
    final success = await _deviceRepo.renameDevice(_deviceId, newName);
    setLoading(false);
    if (!success) setError('重命名失败');
    return success;
  }

  /// 解绑并删除设备（直接清理底表 2 & 底表 3）
  Future<bool> deleteCurrentDevice() async {
    if (_deviceId.isEmpty) return false;
    setLoading(true);
    final ok = await _deviceRepo.deleteDevice(_deviceId);
    setLoading(false);
    return ok;
  }
}
