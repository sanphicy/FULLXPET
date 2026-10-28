// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get login => 'Log In';

  @override
  String get register => 'Sign Up';

  @override
  String get createAccount => 'Create Account';

  @override
  String get forgotPassword => 'Forgot Password';

  @override
  String get phoneLogin => 'Phone';

  @override
  String get emailLogin => 'Email';

  @override
  String get emailHint => 'Enter account / email / phone';

  @override
  String get passwordHint => 'Enter password';

  @override
  String get newPasswordHint => 'Set new password';

  @override
  String get confirmPasswordHint => 'Confirm password';

  @override
  String get enterCode => 'Enter code';

  @override
  String get sendCode => 'Get Code';

  @override
  String get emptyAccountOrPassword => 'Please fill in all fields';

  @override
  String get invalidAccountFormat => 'Invalid account format';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get resetPasswordSuccess =>
      'Password reset successfully, please log in';

  @override
  String get hasAccountGoLogin => 'Already have an account? Log In';

  @override
  String get rememberPasswordGoLogin => 'Remember password? Log In';

  @override
  String get tokenParseError => 'Failed to parse login token, please try again';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get selectCountry => 'Select Country/Region';

  @override
  String get agreePrefix => 'I have read and agree to ';

  @override
  String get userAgreement => 'User Agreement';

  @override
  String get andText => ' and ';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get timesUnit => 'times';

  @override
  String get secondsUnit => 's';

  @override
  String get minutesUnit => 'mins';

  @override
  String get tabDevice => 'Devices';

  @override
  String get tabUsage => 'Statistics';

  @override
  String get tabUser => 'User';

  @override
  String get actionIdle => 'Idle';

  @override
  String get actionAddLitter => 'Add Litter';

  @override
  String get actionEmptyLitter => 'Empty Litter';

  @override
  String get actionResetting => 'Resetting';

  @override
  String get networkError => 'Network Error';

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
  String get myDevices => 'My Devices';

  @override
  String get addDevice => 'Add Device';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get rename => 'Rename';

  @override
  String get delete => 'Delete';

  @override
  String get renameDevice => 'Rename Device';

  @override
  String get deleteDevice => 'Delete Device';

  @override
  String deleteDeviceConfirm(Object name) {
    return 'Are you sure you want to remove device \"$name\"? You will lose control after unbinding.';
  }

  @override
  String get deleteSuccess => 'Device unlinked successfully';

  @override
  String get deleteFailed => 'Failed to delete, please try again';

  @override
  String get deleting => 'Deleting...';

  @override
  String get enterNewDeviceName => 'Enter new device name';

  @override
  String get nameUpdated => 'Device name updated';

  @override
  String get todayToilet => 'Today Visits';

  @override
  String get averageDuration => 'Avg Duration';

  @override
  String get autoMode => 'Auto\nMode';

  @override
  String get dndMode => 'DND\nMode';

  @override
  String get timerMode => 'Timer\nMode';

  @override
  String get manualMode => 'Manual\nMode';

  @override
  String get actionClean => 'Clean';

  @override
  String get actionSmooth => 'Smooth';

  @override
  String get actionDeodorize => 'Deodorize';

  @override
  String get actionChildLock => 'Lock';

  @override
  String get todayLogs => 'Today\'s Activity';

  @override
  String get noLogs => 'No activity recorded';

  @override
  String get deviceSetting => 'Device Settings';

  @override
  String get firmwareVersion => 'Firmware Version';

  @override
  String get serialNumber => 'Serial Number';

  @override
  String get timezoneSetting => 'Time Zone';

  @override
  String get modeAndParams => 'Modes & Configurations';

  @override
  String get autoModeDelay => 'Auto Delay';

  @override
  String get dndTimeRange => 'DND Time Range';

  @override
  String get timerSchedule => 'Timer Schedule';

  @override
  String get moreTools => 'Tools & Support';

  @override
  String get firmwareUpgrade => 'Firmware Upgrade';

  @override
  String get firmwareUpgrading => 'Upgrading...';

  @override
  String get upgrading => 'Upgrading';

  @override
  String get wifiInfo => 'Wi-Fi Information';

  @override
  String get weighingCalibration => 'Scale Calibration';

  @override
  String get helpAndSupport => 'Help & Support';

  @override
  String newFirmwareFound(Object version) {
    return 'New version ($version) detected. Upgrade now? The process takes 1-2 minutes.';
  }

  @override
  String get confirmUpgrade => 'Upgrade';

  @override
  String get upgradeDispatched => 'Upgrade command sent. Detecting status...';

  @override
  String get upgradeSuccess => 'Firmware upgrade completed!';

  @override
  String get upgradeTimeout => 'OTA upgrade timed out, please check device';

  @override
  String get deviceOfflineError => 'Device is offline';

  @override
  String get deviceOperatingError => 'Device is operating, please wait';

  @override
  String get operationSuccess => 'Success';

  @override
  String get operationFailed => 'Operation failed';

  @override
  String get useGuide => 'User Guide';

  @override
  String get guideStep1 => '1. Ensure device is powered on and connected';

  @override
  String get guideStep2 => '2. Tap top-right + button to pair a new device';

  @override
  String get guideStep3 => '3. Swipe left on card to rename or delete';

  @override
  String get guideStep4 => '4. Pull down to refresh device status';

  @override
  String get iUnderstand => 'Got it';

  @override
  String catToiletLog(Object seconds) {
    return 'Cat toilet visit: ${seconds}s';
  }

  @override
  String get scaleCalibrationTitle => 'Scale Calibration';

  @override
  String get scaleStep1Title => 'Preparation';

  @override
  String get scaleStep1Desc =>
      '· Ensure no obstacles around the litter box\n· Ensure device is placed on a hard, flat floor';

  @override
  String get scaleStep2Title => 'Choose Reference Weight';

  @override
  String get scaleStep2Desc =>
      '· Ensure the reference object is between 1000g and 5000g';

  @override
  String get enterWeightInGrams => 'Enter weight in grams';

  @override
  String get selectObjectFromList => 'Place object stably in the center';

  @override
  String get scaleStep3Title => 'Place Reference Object';

  @override
  String get scaleStep3Desc =>
      'Place the reference object into the device chamber';

  @override
  String get scaleStep4Title => 'Calibration Completed';

  @override
  String get scaleStep4Desc => 'Weight sensor calibrated successfully';

  @override
  String get nextStep => 'Next Step';

  @override
  String get done => 'Done';

  @override
  String get invalidWeightError => 'Please enter a valid weight (> 0g)';

  @override
  String get timeZoneTitle => 'Device Time Zone';

  @override
  String get searchTimezoneHint => 'Search timezone (e.g. Asia/Shanghai)...';

  @override
  String useSystemTimezone(Object timezone) {
    return 'Use system timezone ($timezone)';
  }

  @override
  String get noTimerRecord => 'No timer record';

  @override
  String get addTimer => 'Add Timer';

  @override
  String get selectExecutionTime => 'Select Execution Time';

  @override
  String get saveTimersSuccess =>
      'Timers saved and synced to device successfully';

  @override
  String get saveTimersFailed => 'Failed to save timers, please check device';

  @override
  String get wifiInfoTitle => 'Wi-Fi Info';

  @override
  String get networkGood => 'Device network connection is good';

  @override
  String get networkUnstable => 'Device network is unstable or weak';

  @override
  String get wlanName => 'Wi-Fi Name (SSID)';

  @override
  String get wlanStrength => 'Signal Strength (RSSI)';

  @override
  String get ipAddress => 'IP Address';

  @override
  String get macAddress => 'MAC Address';

  @override
  String get resetWifi => 'Reset Wi-Fi';

  @override
  String get resetWifiSuccess =>
      'Reset Wi-Fi command sent, device entering pairing mode';

  @override
  String get latestVersion => 'Latest';

  @override
  String get dataStatistics => 'Data Statistics';

  @override
  String get toiletTimes => 'Toilet Visits';

  @override
  String get toiletDuration => 'Toilet Duration';

  @override
  String get timesTrend => 'Visits Trend';

  @override
  String get durationTrend => 'Duration Trend';

  @override
  String get mon => 'Mon';

  @override
  String get tue => 'Tue';

  @override
  String get wed => 'Wed';

  @override
  String get thu => 'Thu';

  @override
  String get fri => 'Fri';

  @override
  String get sat => 'Sat';

  @override
  String get sun => 'Sun';

  @override
  String get user => 'User';

  @override
  String get personalInfo => 'Personal Info';

  @override
  String get avatar => 'Avatar';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get nickname => 'Nickname';

  @override
  String get editNickname => 'Edit Nickname';

  @override
  String get enterNewNickname => 'Enter new nickname';

  @override
  String get nicknameUpdated => 'Nickname updated successfully';

  @override
  String get accountLabel => 'Account';

  @override
  String get emailLabel => 'Email';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get notBound => 'Not Bound';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get logout => 'Log Out';

  @override
  String get appVersion => 'Version';

  @override
  String get feedback => 'Feedback';

  @override
  String get aboutUs => 'About Us';
}
