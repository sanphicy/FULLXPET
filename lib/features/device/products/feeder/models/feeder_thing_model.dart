enum FeederThingModel {
  resetWlan('1', '重置网络', 'bool'),
  autoMode('2', '自动模式', 'bool'),
  delayMode('3', '定时模式', 'bool'),
  gapingMode('4', '敞开模式', 'bool'),
  semiautomode('5', '半自动模式', 'bool'),
  childLockSwitch('6', '童锁开关', 'bool'),
  deviceStatus('7', '设备当前状态', 'enum'),
  deviceMode('8', '设备当前执行的模式', 'enum: 0自动, 1半自动(红外), 2敞开'),
  gapingState('9', '敞开模式', 'bool'),
  deviceSsid('10', '当前连接的WLAN名称', 'string'),
  deviceRssi('11', '当前连接的WLAN信号', 'value'),
  deviceIp('12', '当前连接的WLAN IP', 'string'),
  deviceMac('13', '设备WLAN MAC', 'string'),
  deviceVersion('14', '设备当前版本', 'string'),
  timerModeSchedule('15', '定时模式-定时设置', 'raw'),
  timeZone('16', '设备时区', 'string'),
  excretionTimesDay('207', '每日进食次数', 'ro'),
  excretionTimeDay('208', '每日进食时长', 'ro'),
  aiResultInform('228', 'AI结果通知', 'ro');

  final String dpid;
  final String description;
  final String dataType;

  const FeederThingModel(this.dpid, this.description, this.dataType);
}

enum FeederMode {
  faceAi(0, '猫脸识别'),
  infrared(1, '红外模式'), // 实际对应半自动(dpid 5)，UI显示为红外模式
  open(2, '敞开模式');

  final int value;
  final String label;
  const FeederMode(this.value, this.label);

  static FeederMode fromValue(int val) {
    return FeederMode.values.firstWhere((e) => e.value == val, orElse: () => FeederMode.open);
  }
}
