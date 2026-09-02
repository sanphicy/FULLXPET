// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class SZh extends S {
  SZh([String locale = 'zh']) : super(locale);

  @override
  String get login => '登录';

  @override
  String get register => '去注册';

  @override
  String get createAccount => '创建账号';

  @override
  String get forgotPassword => '忘记密码';

  @override
  String get phoneLogin => '手机号';

  @override
  String get emailLogin => '邮箱';

  @override
  String get emailHint => '请输入账号/邮箱/手机号';

  @override
  String get passwordHint => '请输入密码';

  @override
  String get newPasswordHint => '设置新密码';

  @override
  String get confirmPasswordHint => '确认密码';

  @override
  String get enterCode => '请输入验证码';

  @override
  String get sendCode => '获取验证码';

  @override
  String get emptyAccountOrPassword => '请填写完整信息';

  @override
  String get invalidAccountFormat => '账号格式不正确';

  @override
  String get passwordMismatch => '两次输入的密码不一致';

  @override
  String get resetPasswordSuccess => '密码重置成功，请重新登录';

  @override
  String get hasAccountGoLogin => '已有账号？去登录';

  @override
  String get rememberPasswordGoLogin => '想起密码？去登录';

  @override
  String get tokenParseError => '登录凭证解析失败，请重试';

  @override
  String get confirm => '确认';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get selectCountry => '选择国家/地区';

  @override
  String get agreePrefix => '我已阅读并同意';

  @override
  String get userAgreement => '《用户协议》';

  @override
  String get andText => '和';

  @override
  String get privacyPolicy => '《隐私政策》';

  @override
  String get timesUnit => '次';

  @override
  String get secondsUnit => '秒';

  @override
  String get minutesUnit => '分钟';

  @override
  String get tabDevice => '设备';

  @override
  String get tabUsage => '概况';

  @override
  String get tabUser => '用户';

  @override
  String get actionIdle => '空闲中';

  @override
  String get actionAddLitter => '加砂';

  @override
  String get actionEmptyLitter => '清砂';

  @override
  String get actionResetting => '复位中';

  @override
  String get networkError => '网络连接失败，请检查网络设置';

  @override
  String get wifiConfigTitle => '配置设备网络';

  @override
  String get selectWifiTitle => '选择设备的 Wi-Fi';

  @override
  String get wifiConfigDesc => '请选择 Wi-Fi 网络并输入密码。';

  @override
  String get wifiPasswordHint => '请输入 Wi-Fi 密码';

  @override
  String get searchingLabel => '搜索设备';

  @override
  String get startConfig => '开始配网';

  @override
  String get configProgress => '正在配网中...';

  @override
  String get configStep1 => '正在向设备下发网络信息';

  @override
  String get configStep2 => '设备正在连接路由器';

  @override
  String get configStep3 => '正在向云端注册设备';

  @override
  String get configSuccess => '设备添加成功！';

  @override
  String get autoSearching => '正在自动搜索可用设备...';

  @override
  String get noDeviceFoundDesc => '当前未连接设备，请点击下方进行连接。';

  @override
  String get searchingAvailable => '正在搜索可用设备';

  @override
  String get myDevices => '我的设备';

  @override
  String get addDevice => '添加设备';

  @override
  String get online => '在线';

  @override
  String get offline => '离线';

  @override
  String get rename => '重命名';

  @override
  String get delete => '删除';

  @override
  String get renameDevice => '修改设备名称';

  @override
  String get deleteDevice => '删除设备';

  @override
  String deleteDeviceConfirm(Object name) {
    return '确定要删除设备 \"$name\" 吗？解绑后设备将无法在 App 中操控。';
  }

  @override
  String get deleteSuccess => '设备已成功解绑与删除';

  @override
  String get deleteFailed => '删除失败，请稍后重试';

  @override
  String get deleting => '正在删除...';

  @override
  String get enterNewDeviceName => '请输入新的设备名称';

  @override
  String get nameUpdated => '设备名称修改成功';

  @override
  String get todayToilet => '今日如厕';

  @override
  String get averageDuration => '平均时长';

  @override
  String get autoMode => '自动\n模式';

  @override
  String get dndMode => '勿扰\n模式';

  @override
  String get timerMode => '定时\n模式';

  @override
  String get manualMode => '手动\n模式';

  @override
  String get actionClean => '清理';

  @override
  String get actionSmooth => '抚平';

  @override
  String get actionDeodorize => '除臭';

  @override
  String get actionChildLock => '童锁';

  @override
  String get todayLogs => '今日运行动态';

  @override
  String get noLogs => '暂无相关动态';

  @override
  String get deviceSetting => '设备设置';

  @override
  String get firmwareVersion => '固件版本';

  @override
  String get serialNumber => '设备序列号';

  @override
  String get timezoneSetting => '时区设置';

  @override
  String get modeAndParams => '模式与参数配置';

  @override
  String get autoModeDelay => '自动模式延时';

  @override
  String get dndTimeRange => '勿扰时间段';

  @override
  String get timerSchedule => '定时模式计划';

  @override
  String get moreTools => '更多工具与辅助';

  @override
  String get firmwareUpgrade => '固件升级';

  @override
  String get firmwareUpgrading => '固件升级中...';

  @override
  String get upgrading => '升级中';

  @override
  String get wifiInfo => 'Wi-Fi 信息';

  @override
  String get weighingCalibration => '称重校准';

  @override
  String get helpAndSupport => '使用帮助与支持';

  @override
  String newFirmwareFound(Object version) {
    return '检测到新版本 ($version)，是否立即升级？升级过程约需要 1~2 分钟。';
  }

  @override
  String get confirmUpgrade => '确认升级';

  @override
  String get upgradeDispatched => '升级指令已下发，正在检测升级状态...';

  @override
  String get upgradeSuccess => '固件升级完成！';

  @override
  String get upgradeTimeout => 'OTA 升级超时，请检查设备状态';

  @override
  String get deviceOfflineError => '设备离线无法操作';

  @override
  String get deviceOperatingError => '设备正在运行中，请稍后操作';

  @override
  String get operationSuccess => '操作成功';

  @override
  String get operationFailed => '操作失败';

  @override
  String get useGuide => '使用指南';

  @override
  String get guideStep1 => '1. 确保设备已开启并连接网络';

  @override
  String get guideStep2 => '2. 点击右上角 + 按钮添加新设备';

  @override
  String get guideStep3 => '3. 向左滑动设备卡片可重命名或删除';

  @override
  String get guideStep4 => '4. 下拉列表可手动刷新设备状态';

  @override
  String get iUnderstand => '我知道了';

  @override
  String catToiletLog(Object seconds) {
    return '猫咪本次如厕: $seconds秒';
  }

  @override
  String get scaleCalibrationTitle => '称重校准';

  @override
  String get scaleStep1Title => '称重校准准备';

  @override
  String get scaleStep1Desc => '· 确保猫砂盆四周无任何遮挡与碰撞物\n· 确保猫砂盆平稳放置在坚硬平整的地面上';

  @override
  String get scaleStep2Title => '选择校准参考物';

  @override
  String get scaleStep2Desc => '· 请确保参考物体重量在 1000g - 5000g 之间';

  @override
  String get enterWeightInGrams => '请输入参考物重量 (单位: 克)';

  @override
  String get selectObjectFromList => '请将参考物平稳放入盆内中央';

  @override
  String get scaleStep3Title => '放入参考物';

  @override
  String get scaleStep3Desc => '请将已知重量的参考物放入设备桶仓中央';

  @override
  String get scaleStep4Title => '校准完成';

  @override
  String get scaleStep4Desc => '设备已成功完成称重传感器标定';

  @override
  String get nextStep => '下一步';

  @override
  String get done => '完成';

  @override
  String get invalidWeightError => '请输入合法的重量数值 (大于 0g)';

  @override
  String get timeZoneTitle => '设备时区';

  @override
  String get searchTimezoneHint => '搜索时区 (例如: Asia/Shanghai)...';

  @override
  String useSystemTimezone(Object timezone) {
    return '使用手机当前系统时区 ($timezone)';
  }

  @override
  String get noTimerRecord => '暂无定时任务记录';

  @override
  String get addTimer => '添加定时';

  @override
  String get selectExecutionTime => '选择执行时间';

  @override
  String get saveTimersSuccess => '定时任务已成功保存并同步至设备';

  @override
  String get saveTimersFailed => '定时任务保存失败，请检查设备状态';

  @override
  String get wifiInfoTitle => 'Wi-Fi 信息';

  @override
  String get networkGood => '设备当前 Wi-Fi 网络连接良好';

  @override
  String get networkUnstable => '设备当前 Wi-Fi 信号较弱或网络不稳定';

  @override
  String get wlanName => 'Wi-Fi 名称 (SSID)';

  @override
  String get wlanStrength => '信号强度 (RSSI)';

  @override
  String get ipAddress => 'IP 地址';

  @override
  String get macAddress => 'MAC 地址';

  @override
  String get resetWifi => '重置 Wi-Fi';

  @override
  String get resetWifiSuccess => '重置 Wi-Fi 指令已发送，设备即将重启配网模式';

  @override
  String get latestVersion => '最新';

  @override
  String get dataStatistics => '数据统计';

  @override
  String get toiletTimes => '如厕次数';

  @override
  String get toiletDuration => '如厕时长';

  @override
  String get timesTrend => '如厕次数趋势';

  @override
  String get durationTrend => '如厕时长趋势';

  @override
  String get mon => '周一';

  @override
  String get tue => '周二';

  @override
  String get wed => '周三';

  @override
  String get thu => '周四';

  @override
  String get fri => '周五';

  @override
  String get sat => '周六';

  @override
  String get sun => '周日';

  @override
  String get user => '用户';

  @override
  String get personalInfo => '个人信息';

  @override
  String get avatar => '头像';

  @override
  String get chooseFromGallery => '从相册选择';

  @override
  String get takePhoto => '拍照';

  @override
  String get nickname => '昵称';

  @override
  String get editNickname => '修改昵称';

  @override
  String get enterNewNickname => '请输入新昵称';

  @override
  String get nicknameUpdated => '昵称已修改';

  @override
  String get accountLabel => '账号';

  @override
  String get emailLabel => '邮箱';

  @override
  String get phoneLabel => '手机号';

  @override
  String get notBound => '未绑定';

  @override
  String get deleteAccount => '注销账号';

  @override
  String get logout => '退出登录';

  @override
  String get appVersion => '软件版本';

  @override
  String get feedback => '意见反馈';

  @override
  String get aboutUs => '关于我们';
}
