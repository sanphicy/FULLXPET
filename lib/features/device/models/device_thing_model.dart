import 'package:fullxpet/common/l10n/app_localizations.dart';

enum DeviceThingModel {
  resetWlan('1', '重置网络', 'bool'),
  cleanCatLitter('2', '清理猫砂', 'bool'),
  flatCatLitter('3', '抚平猫砂', 'bool'),
  emptyCatLitter('4', '倾空猫砂', 'bool'),
  addCatLitter('5', '添加猫砂', 'bool'),
  deviceReset('6', '手动复位', 'bool'),
  childLockSwitch('7', '童锁开关', 'bool'),
  deviceStatus('8', '设备当前状态', 'enum: 0空闲, 1执行, 2暂停'),
  deviceExecute('9', '设备当前执行操作', 'enum: 0无执行, 1清理, 2抚平, 3加沙, 4清砂, 5复位'),
  deviceMode('10', '设备当前执行的模式', 'enum: 0自动, 1定时, 2手动'),
  notdisturbModeStatus('11', '勿扰模式状态', 'bool'),
  deviceSsid('12', '当前连接的WLAN名称', 'string'),
  deviceRssi('13', '当前连接的WLAN信号', 'value'),
  deviceIp('14', '当前连接的WLAN IP', 'string'),
  deviceMac('15', '设备WLAN MAC', 'string'),
  deviceVersion('16', '设备当前版本', 'string'),
  autoModeDelay('17', '自动模式-延时设置(秒)', 'value'),
  timerModeSchedule('18', '定时模式-定时设置', 'raw'),
  notdisturbModeSchedule('19', '勿扰模式-定时设置', 'string'),
  timeZone('20', '设备时区', 'string'),
  installLoose('21', '设备卡扣安装情况', 'bool'),
  catEntry('22', '猫咪进入', 'bool'),
  motorOverload('23', '电机过载', 'bool'),
  faultReset('24', '复位异常', 'bool'),
  shitWeight('25', '当前设备粪便重量', 'int'),
  litterWeight('26', '当前设备猫砂重量', 'int'),
  prepareCalibration('27', '准备称重校准', 'bool'),
  calibration('28', '称重校准', 'bool'),
  palsmaState('29', '等离子状态', 'bool'),
  calibrationWeight('30', '称重校准下发重量', 'int'),
  excretionTimesDay('207', '每天排泄次数', 'value'),
  excretionTimeDay('208', '每次排泄时长(秒)', 'value');

  final String dpid;
  final String description;
  final String dataType;

  const DeviceThingModel(this.dpid, this.description, this.dataType);
}

enum WorkMode {
  auto(0),
  timer(1),
  manual(2);

  final int value;
  const WorkMode(this.value);

  static WorkMode fromValue(int val) {
    return WorkMode.values.firstWhere((e) => e.value == val, orElse: () => WorkMode.auto);
  }

  String getLocalizedLabel(S s) {
    switch (this) {
      case WorkMode.auto:
        return s.autoMode;
      case WorkMode.timer:
        return s.timerMode;
      case WorkMode.manual:
        return s.manualMode;
    }
  }
}

enum ExecuteAction {
  idle(0),
  cleaning(1),
  smoothing(2),
  adding(3),
  emptying(4),
  resetting(5);

  final int value;
  const ExecuteAction(this.value);

  static ExecuteAction fromValue(int val) {
    return ExecuteAction.values.firstWhere((e) => e.value == val, orElse: () => ExecuteAction.idle);
  }

  String getLocalizedLabel(S s) {
    switch (this) {
      case ExecuteAction.idle:
        return s.actionIdle;
      case ExecuteAction.cleaning:
        return s.actionClean;
      case ExecuteAction.smoothing:
        return s.actionSmooth;
      case ExecuteAction.adding:
        return s.actionAddLitter;
      case ExecuteAction.emptying:
        return s.actionEmptyLitter;
      case ExecuteAction.resetting:
        return s.actionResetting;
    }
  }
}
