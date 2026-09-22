import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/core/utils/time_utils.dart';
import 'package:fullxpet/features/device/feeder/models/feeder_thing_model.dart';
import 'package:fullxpet/features/device/models/device_dto.dart';
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

class FeederViewModel extends BaseProvider {
  final DeviceRepository _deviceRepo = locator<DeviceRepository>();

  DeviceDto? _device;
  DeviceDto? get device => _device;

  StreamSubscription<String>? _repoSubscription;
  Timer? _otaPollingTimer;

  // --- OTA 升级相关状态 ---
  bool get hasNewFirmware => _device?.hasNewFirmware ?? false;
  String get newFirmwareVersion => _device?.newFirmwareVersion ?? '';
  bool get isOtaUpdating => _device?.isOtaUpdating ?? false;

  FeederMode get currentMode {
    final val = _device?.attributes[FeederThingModel.deviceMode.dpid];
    final int modeVal = int.tryParse(val?.toString() ?? '') ?? 2;
    return FeederMode.fromValue(modeVal);
  }

  bool get isDoorDispensed {
    final val = _device?.attributes[FeederThingModel.gapingState.dpid];
    return val == true || val?.toString() == 'true';
  }

  bool get isChildLock {
    final val = _device?.attributes[FeederThingModel.childLockSwitch.dpid];
    return val == true || val?.toString() == 'true';
  }

  int get deviceStatus {
    final val = _device?.attributes[FeederThingModel.deviceStatus.dpid];
    return int.tryParse(val?.toString() ?? '') ?? 0;
  }

  String get firmwareVersion =>
      _device?.attributes[FeederThingModel.deviceVersion.dpid]?.toString() ?? (_device?.firmwareVersion ?? '');

  String get wifiSsid => _device?.attributes[FeederThingModel.deviceSsid.dpid]?.toString() ?? (_device?.wifiSsid ?? '');

  String get wifiRssi => "${_device?.attributes[FeederThingModel.deviceRssi.dpid] ?? 0}dBm";

  String get wifiIp => _device?.attributes[FeederThingModel.deviceIp.dpid]?.toString() ?? '-';

  String get wifiMac => _device?.attributes[FeederThingModel.deviceMac.dpid]?.toString() ?? '-';

  List<FeederTimeRange> get timerRanges {
    final val = _device?.attributes[FeederThingModel.timerModeSchedule.dpid];
    if (val == null) return [];
    try {
      final List<dynamic> rawList = jsonDecode(val.toString());
      List<FeederTimeRange> result = [];
      for (int i = 0; i < rawList.length - 1; i += 2) {
        final startSec = int.tryParse(rawList[i].toString()) ?? 0;
        final endSec = int.tryParse(rawList[i + 1].toString()) ?? 0;
        result.add(FeederTimeRange(start: TimeUtils.secondsToTime(startSec), end: TimeUtils.secondsToTime(endSec)));
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  FeederViewModel() {
    _repoSubscription = _deviceRepo.onDeviceUpdated.listen((updatedDeviceId) {
      if (_device != null && _device!.deviceId == updatedDeviceId) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    stopOtaPolling();
    _repoSubscription?.cancel();
    super.dispose();
  }

  Future<void> initDevice(String deviceId) async {
    _device = _deviceRepo.getDevice(deviceId);
    notifyListeners();

    setLoading(true);
    try {
      await _deviceRepo.fetchDeviceProperties(deviceId);
      // 检查固件版本
      await checkFirmwareUpdate();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  /// 检查是否有新固件
  Future<void> checkFirmwareUpdate() async {
    if (_device == null) return;
    try {
      final otaData = await _deviceRepo.checkPendingFirmware(_device!.deviceId);
      if (otaData != null && otaData['recordId'] != null) {
        _device!.hasNewFirmware = true;
        _device!.newFirmwareVersion = otaData['version']?.toString() ?? '最新';
        _device!.pendingOtaRecordId = otaData['recordId'].toString();
      } else {
        _device!.hasNewFirmware = false;
        _device!.newFirmwareVersion = '';
        _device!.pendingOtaRecordId = '';
      }
      notifyListeners();
    } catch (_) {}
  }

  /// 触发固件升级
  Future<bool> startFirmwareUpgrade({int timeoutSeconds = 120}) async {
    if (_device == null || _device!.pendingOtaRecordId.isEmpty) {
      setError('没有要升级的固件');
      return false;
    }

    setLoading(true);
    final targetVersion = _device!.newFirmwareVersion;
    final success = await _deviceRepo.dispatchFirmwareUpgrade(_device!.deviceId, _device!.pendingOtaRecordId);
    setLoading(false);

    if (success) {
      _device!.hasNewFirmware = false;
      _device!.isOtaUpdating = true;
      notifyListeners();
      _startOtaPolling(_device!.deviceId, targetVersion, timeoutSeconds);
      return true;
    } else {
      setError('下发固件升级失败');
      return false;
    }
  }

  void _startOtaPolling(String deviceId, String targetVersion, int timeoutSeconds) {
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
        await _deviceRepo.fetchDeviceProperties(deviceId);
        if (_device != null && _device!.firmwareVersion == targetVersion) {
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
    if (_device != null) {
      _device!.isOtaUpdating = false;
    }
  }

  /// 重命名设备
  Future<bool> updateDeviceName(String newName) async {
    if (_device == null) return false;
    setLoading(true);
    final success = await _deviceRepo.renameDevice(_device!.deviceId, newName);
    setLoading(false);
    if (!success) setError('重命名失败');
    return success;
  }

  Future<void> switchMode(FeederMode mode) async {
    if (_device == null || currentMode == mode) return;

    final deviceId = _device!.deviceId;
    final List<Map<String, dynamic>> commandPayload = [];

    switch (mode) {
      case FeederMode.open:
        commandPayload.add({'dpid': FeederThingModel.gapingMode.dpid, 'value': true});
        break;
      case FeederMode.timer:
        commandPayload.add({'dpid': FeederThingModel.delayMode.dpid, 'value': true});
        break;
      case FeederMode.faceAi:
        commandPayload.add({'dpid': FeederThingModel.autoMode.dpid, 'value': true});
        break;
    }

    _device!.updateAttributesFromMap({FeederThingModel.deviceMode.dpid: mode.value});
    notifyListeners();

    final success = await _deviceRepo.sendDeviceCommand(deviceId, commandPayload);
    if (!success) {
      await _deviceRepo.fetchDeviceProperties(deviceId);
      setError("切换模式失败，请检查设备在线状态");
      notifyListeners();
    }
  }

  Future<void> toggleFeedSwitch() async {
    if (_device == null || currentMode != FeederMode.open) return;

    final deviceId = _device!.deviceId;
    final targetState = !isDoorDispensed;

    _device!.updateAttributesFromMap({FeederThingModel.gapingState.dpid: targetState});
    notifyListeners();

    final success = await _deviceRepo.sendDeviceCommand(deviceId, [
      {'dpid': FeederThingModel.gapingState.dpid, 'value': targetState},
    ]);

    if (!success) {
      _device!.updateAttributesFromMap({FeederThingModel.gapingState.dpid: !targetState});
      setError("控制推杆失败");
      notifyListeners();
    }
  }

  Future<void> toggleChildLock() async {
    if (_device == null) return;

    final deviceId = _device!.deviceId;
    final targetState = !isChildLock;

    _device!.updateAttributesFromMap({FeederThingModel.childLockSwitch.dpid: targetState});
    notifyListeners();

    final success = await _deviceRepo.sendDeviceCommand(deviceId, [
      {'dpid': FeederThingModel.childLockSwitch.dpid, 'value': targetState},
    ]);

    if (!success) {
      _device!.updateAttributesFromMap({FeederThingModel.childLockSwitch.dpid: !targetState});
      setError("设置童锁失败");
      notifyListeners();
    }
  }

  Future<bool> addTimerRange(String start, String end) async {
    final list = List<FeederTimeRange>.from(timerRanges);
    list.add(FeederTimeRange(start: start, end: end));
    return await _saveTimerRanges(list);
  }

  Future<bool> removeTimerRange(int index) async {
    final list = List<FeederTimeRange>.from(timerRanges);
    list.removeAt(index);
    return await _saveTimerRanges(list);
  }

  Future<bool> _saveTimerRanges(List<FeederTimeRange> list) async {
    if (_device == null) return false;

    final List<String> secondsArray = [];
    for (var range in list) {
      secondsArray.add(range.startSeconds.toString());
      secondsArray.add(range.endSeconds.toString());
    }

    final jsonStr = jsonEncode(secondsArray);
    _device!.updateAttributesFromMap({FeederThingModel.timerModeSchedule.dpid: jsonStr});
    notifyListeners();

    return await _deviceRepo.sendDeviceCommand(_device!.deviceId, [
      {'dpid': FeederThingModel.timerModeSchedule.dpid, 'value': jsonStr},
    ]);
  }

  Future<bool> resetWifi() async {
    if (_device == null) return false;
    return await _deviceRepo.sendDeviceCommand(_device!.deviceId, [
      {'dpid': FeederThingModel.resetWlan.dpid, 'value': true},
    ]);
  }
}
