import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S? of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @login.
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get login;

  /// No description provided for @register.
  ///
  /// In zh, this message translates to:
  /// **'注册'**
  String get register;

  /// No description provided for @emailLabel.
  ///
  /// In zh, this message translates to:
  /// **'邮箱'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入您的邮箱'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入您的密码'**
  String get passwordHint;

  /// No description provided for @forgotPassword.
  ///
  /// In zh, this message translates to:
  /// **'忘记密码'**
  String get forgotPassword;

  /// No description provided for @agreePrefix.
  ///
  /// In zh, this message translates to:
  /// **'我已阅读并同意 '**
  String get agreePrefix;

  /// No description provided for @userAgreement.
  ///
  /// In zh, this message translates to:
  /// **'用户协议'**
  String get userAgreement;

  /// No description provided for @privacyPolicy.
  ///
  /// In zh, this message translates to:
  /// **'隐私政策'**
  String get privacyPolicy;

  /// No description provided for @agreeTermsPrompt.
  ///
  /// In zh, this message translates to:
  /// **'请先勾选同意用户协议与隐私政策'**
  String get agreeTermsPrompt;

  /// No description provided for @confirmPassword.
  ///
  /// In zh, this message translates to:
  /// **'确认密码'**
  String get confirmPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In zh, this message translates to:
  /// **'请输入新密码'**
  String get enterNewPassword;

  /// No description provided for @sendCode.
  ///
  /// In zh, this message translates to:
  /// **'发送验证码'**
  String get sendCode;

  /// No description provided for @enterCode.
  ///
  /// In zh, this message translates to:
  /// **'请输入验证码'**
  String get enterCode;

  /// No description provided for @submitAndRegister.
  ///
  /// In zh, this message translates to:
  /// **'提交并注册'**
  String get submitAndRegister;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get confirm;

  /// No description provided for @connectBtn.
  ///
  /// In zh, this message translates to:
  /// **'连接'**
  String get connectBtn;

  /// No description provided for @andText.
  ///
  /// In zh, this message translates to:
  /// **' 和'**
  String get andText;

  /// No description provided for @wifiConfigTitle.
  ///
  /// In zh, this message translates to:
  /// **'配置设备网络'**
  String get wifiConfigTitle;

  /// No description provided for @selectWifiTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择设备的 Wi-Fi'**
  String get selectWifiTitle;

  /// No description provided for @wifiConfigDesc.
  ///
  /// In zh, this message translates to:
  /// **'请选择 2.4GHz 的 Wi-Fi 网络并输入密码，暂不支持 5G 网络。'**
  String get wifiConfigDesc;

  /// No description provided for @wifiPasswordHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入 Wi-Fi 密码'**
  String get wifiPasswordHint;

  /// No description provided for @searchingLabel.
  ///
  /// In zh, this message translates to:
  /// **'搜索设备'**
  String get searchingLabel;

  /// No description provided for @startConfig.
  ///
  /// In zh, this message translates to:
  /// **'开始配网'**
  String get startConfig;

  /// No description provided for @configProgress.
  ///
  /// In zh, this message translates to:
  /// **'正在配网中...'**
  String get configProgress;

  /// No description provided for @configStep1.
  ///
  /// In zh, this message translates to:
  /// **'正在向设备下发网络信息'**
  String get configStep1;

  /// No description provided for @configStep2.
  ///
  /// In zh, this message translates to:
  /// **'设备正在连接路由器'**
  String get configStep2;

  /// No description provided for @configStep3.
  ///
  /// In zh, this message translates to:
  /// **'正在向云端注册设备'**
  String get configStep3;

  /// No description provided for @configSuccess.
  ///
  /// In zh, this message translates to:
  /// **'设备添加成功！'**
  String get configSuccess;

  /// No description provided for @autoSearching.
  ///
  /// In zh, this message translates to:
  /// **'正在自动搜索可用设备...'**
  String get autoSearching;

  /// No description provided for @noDeviceFoundDesc.
  ///
  /// In zh, this message translates to:
  /// **'当前未连接设备，请点击下方进行连接。'**
  String get noDeviceFoundDesc;

  /// No description provided for @searchingAvailable.
  ///
  /// In zh, this message translates to:
  /// **'正在搜索可用设备'**
  String get searchingAvailable;

  /// No description provided for @emptyAccountOrPassword.
  ///
  /// In zh, this message translates to:
  /// **'账号或密码不能为空'**
  String get emptyAccountOrPassword;

  /// No description provided for @invalidAccountFormat.
  ///
  /// In zh, this message translates to:
  /// **'请输入合法的邮箱或手机号'**
  String get invalidAccountFormat;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'zh':
      return SZh();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
