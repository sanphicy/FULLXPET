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
  String get register => '注册';

  @override
  String get emailLabel => '邮箱';

  @override
  String get emailHint => '请输入您的邮箱';

  @override
  String get passwordHint => '请输入您的密码';

  @override
  String get forgotPassword => '忘记密码';

  @override
  String get agreePrefix => '我已阅读并同意 ';

  @override
  String get userAgreement => '用户协议';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get agreeTermsPrompt => '请先勾选同意用户协议与隐私政策';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get enterNewPassword => '请输入新密码';

  @override
  String get sendCode => '发送验证码';

  @override
  String get enterCode => '请输入验证码';

  @override
  String get submitAndRegister => '提交并注册';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确定';

  @override
  String get connectBtn => '连接';

  @override
  String get andText => ' 和';

  @override
  String get wifiConfigTitle => '配置设备网络';

  @override
  String get selectWifiTitle => '选择设备的 Wi-Fi';

  @override
  String get wifiConfigDesc => '请选择 2.4GHz 的 Wi-Fi 网络并输入密码，暂不支持 5G 网络。';

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
  String get emptyAccountOrPassword => '账号或密码不能为空';

  @override
  String get invalidAccountFormat => '请输入合法的邮箱或手机号';
}
