enum FeederThingModel {
  resetWlan('1', '重置网络', 'bool'),
  autoMode('2', '自动模式', 'bool'),
  delayMode('3', '定时模式', 'bool'),
  gapingMode('4', '敞开模式', 'bool'),
  childLockSwitch('5', '童锁开关', 'bool'),
  deviceStatus('6', '设备当前状态', 'int'),
  deviceMode('7', '设备当前执行的模式', 'enum: 0自动, 1定时, 2敞开'),
  gapingState('8', '敞开模式状态/推杆', 'bool'),
  deviceSsid('9', '当前连接的WLAN名称', 'string'),
  deviceRssi('10', '当前连接的WLAN信号', 'value'),
  deviceIp('11', '当前连接的WLAN IP', 'string'),
  deviceMac('12', '设备WLAN MAC', 'string'),
  deviceVersion('13', '设备当前版本', 'string'),
  timerModeSchedule('14', '定时模式-定时设置', 'raw'),
  timeZone('15', '设备时区', 'string');

  final String dpid;
  final String description;
  final String dataType;

  const FeederThingModel(this.dpid, this.description, this.dataType);
}

enum FeederMode {
  faceAi(0, '猫脸识别'),
  timer(1, '定时出粮'),
  open(2, '敞开模式');

  final int value;
  final String label;
  const FeederMode(this.value, this.label);

  static FeederMode fromValue(int val) {
    return FeederMode.values.firstWhere((e) => e.value == val, orElse: () => FeederMode.open);
  }
}
