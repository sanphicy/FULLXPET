import 'dart:async';
import 'dart:convert';
import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/core/utils/time_utils.dart';
import 'package:fullxpet/features/device/feeder/models/feeder_thing_model.dart';
import 'package:fullxpet/features/device/models/device_dto.dart';
import 'package:fullxpet/features/device/repositories/device_repository.dart';
import 'package:fullxpet/locator.dart';

/// 定时区间实体
class FeederTimeRange {
  final String start; // 如 "08:00"
  final String end; // 如 "22:00"

  FeederTimeRange({required this.start, required this.end});

  int get startSeconds => TimeUtils.timeToSeconds(start);
  int get endSeconds => TimeUtils.timeToSeconds(end);
}

class FeederViewModel extends BaseProvider {
  final DeviceRepository _deviceRepo = locator<DeviceRepository>();

  DeviceDto? _device;
  DeviceDto? get device => _device;

  StreamSubscription<String>? _repoSubscription;

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

  String get firmwareVersion => _device?.attributes[FeederThingModel.deviceVersion.dpid]?.toString() ?? '';

  String get wifiRssi => "${_device?.attributes[FeederThingModel.deviceRssi.dpid] ?? 0}dBm";

  String get wifiIp => _device?.attributes[FeederThingModel.deviceIp.dpid]?.toString() ?? '-';

  String get wifiMac => _device?.attributes[FeederThingModel.deviceMac.dpid]?.toString() ?? '-';

  /// 解析成对的时间区间列表 (DP 14: ["28800","79200", ...])
  List<FeederTimeRange> get timerRanges {
    final val = _device?.attributes[FeederThingModel.timerModeSchedule.dpid];
    if (val == null) return [];
    try {
      final List<dynamic> rawList = jsonDecode(val.toString());
      List<FeederTimeRange> result = [];
      // 步长为 2 遍历，两两成对
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
    _repoSubscription?.cancel();
    super.dispose();
  }

  Future<void> initDevice(String deviceId) async {
    _device = _deviceRepo.getDevice(deviceId);
    notifyListeners();

    setLoading(true);
    try {
      await _deviceRepo.fetchDeviceProperties(deviceId);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
      notifyListeners();
    }
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

  /// 添加时间区间
  Future<bool> addTimerRange(String start, String end) async {
    final list = List<FeederTimeRange>.from(timerRanges);
    list.add(FeederTimeRange(start: start, end: end));
    return await _saveTimerRanges(list);
  }

  /// 移除时间区间
  Future<bool> removeTimerRange(int index) async {
    final list = List<FeederTimeRange>.from(timerRanges);
    list.removeAt(index);
    return await _saveTimerRanges(list);
  }

  /// 转换成下发数组：["28800", "79200", ...]
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
