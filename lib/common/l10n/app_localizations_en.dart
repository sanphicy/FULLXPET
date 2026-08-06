// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get emailLabel => 'Account';

  @override
  String get emailHint => 'Enter email or phone number';

  @override
  String get passwordHint => 'Enter password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get agreePrefix => 'I have read and agree to the ';

  @override
  String get userAgreement => 'User Agreement';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get agreeTermsPrompt => 'Please read and agree to the terms first';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get enterNewPassword => 'Enter new password';

  @override
  String get sendCode => 'Send Code';

  @override
  String get enterCode => 'Enter Code';

  @override
  String get submitAndRegister => 'Submit & Register';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get connectBtn => 'Connect';

  @override
  String get andText => ' and ';

  @override
  String get wifiConfigTitle => 'Wi-Fi Configuration';

  @override
  String get selectWifiTitle => 'Select Wi-Fi';

  @override
  String get wifiConfigDesc =>
      'Please connect to a 2.4GHz Wi-Fi (5G is not supported)';

  @override
  String get wifiPasswordHint => 'Enter Wi-Fi password';

  @override
  String get searchingLabel => 'Searching...';

  @override
  String get startConfig => 'Start Configuration';

  @override
  String get configProgress => 'Configuring...';

  @override
  String get configStep1 => 'Connecting to device...';

  @override
  String get configStep2 => 'Connecting to cloud...';

  @override
  String get configStep3 => 'Initializing...';

  @override
  String get configSuccess => 'Configuration Successful';

  @override
  String get autoSearching => 'Auto searching...';

  @override
  String get noDeviceFoundDesc =>
      'No devices found nearby. Please ensure the device is powered on.';

  @override
  String get searchingAvailable => 'Searching for available devices...';

  @override
  String get emptyAccountOrPassword => 'Account or password cannot be empty';

  @override
  String get invalidAccountFormat =>
      'Please enter a valid email or phone number';
}
