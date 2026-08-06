enum DeviceThingModel {
  // 基础控制
  resetWlan('1', '重置网络', 'bool'),
  cleanCatLitter('2', '清理猫砂', 'bool'),
  flatCatLitter('3', '抚平猫砂', 'bool'),
  emptyCatLitter('4', '倾空猫砂', 'bool'),
  addCatLitter('5', '添加猫砂', 'bool'),
  deviceReset('6', '手动复位', 'bool'),
  childLockSwitch('7', '童锁开关', 'bool'),

  // 状态与模式
  deviceStatus('8', '设备当前状态', 'enum: 0空闲, 1执行, 2暂停'),
  deviceExecute('9', '设备当前执行操作', 'enum: 0无执行, 1清理, 2抚平, 3加沙, 4清砂, 5复位'),
  deviceMode('10', '设备当前执行的模式', 'enum: 0自动, 1定时, 2手动'),
  notdisturbModeStatus('11', '勿扰模式状态', 'bool'),

  // 网络与固件
  deviceSsid('12', '当前连接的WLAN名称', 'string'),
  deviceRssi('13', '当前连接的WLAN信号', 'value'),
  deviceIp('14', '当前连接的WLAN IP', 'string'),
  deviceMac('15', '设备WLAN MAC', 'string'),
  deviceVersion('16', '设备当前版本', 'string'),

  // 设置与配置
  autoModeDelay('17', '自动模式-延时设置(秒)', 'value'),
  timerModeSchedule('18', '定时模式-定时设置', 'raw'),
  notdisturbModeSchedule('19', '勿扰模式-定时设置', 'string'),
  timeZone('20', '设备时区', 'string'),

  // 告警与通知
  installLoose('21', '设备卡扣安装情况', 'bool'),
  catEntry('22', '猫咪进入', 'bool'),
  motorOverload('23', '电机过载', 'bool'),
  faultReset('24', '复位异常', 'bool'),

  // 传感器数据
  shitWeight('25', '当前设备粪便重量', 'int'),
  litterWeight('26', '当前设备猫砂重量', 'int'),

  // 校准与周边功能
  prepareCalibration('27', '准备称重校准', 'bool'),
  calibration('28', '称重校准', 'bool'),
  palsmaState('29', '等离子状态', 'bool'),
  calibrationWeight('30', '称重校准下发重量', 'int'),

  // 统计功能
  excretionTimesDay('207', '每天排泄次数', 'value'),
  excretionTimeDay('208', '每次排泄时长(秒)', 'value');

  final String dpid;
  final String description;
  final String dataType;

  const DeviceThingModel(this.dpid, this.description, this.dataType);

  static DeviceThingModel? fromDpid(String dpid) {
    for (var model in DeviceThingModel.values) {
      if (model.dpid == dpid) {
        return model;
      }
    }
    return null;
  }
}

// 运行模式枚举 DPID 10
enum WorkMode {
  auto(0, '自动模式'),
  timer(1, '定时模式'),
  manual(2, '手动模式');

  final int value;
  final String label;
  const WorkMode(this.value, this.label);

  static WorkMode fromValue(int val) {
    return WorkMode.values.firstWhere((e) => e.value == val, orElse: () => WorkMode.auto);
  }
}

//执行状态枚举 DPID 9
enum ExecuteAction {
  idle(0, '无执行'),
  cleaning(1, '清理'),
  smoothing(2, '抚平'),
  adding(3, '加沙'),
  emptying(4, '清砂'),
  resetting(5, '复位');

  final int value;
  final String label;
  const ExecuteAction(this.value, this.label);

  static ExecuteAction fromValue(int val) {
    return ExecuteAction.values.firstWhere((e) => e.value == val, orElse: () => ExecuteAction.idle);
  }
}
