import 'dart:ui';
import 'package:flutter/foundation.dart';

/// 全局语言状态管理（默认跟随系统，预留手动切换入口）
class LocaleProvider extends ChangeNotifier {
  Locale? _overrideLocale;
  Locale? get overrideLocale => _overrideLocale;

  String _activeLocaleCode = _normalize(PlatformDispatcher.instance.locale);

  /// 供接口 locale Query 参数使用（始终与当前界面生效语言一致：zh / en）
  String get apiLocale => _overrideLocale != null ? _normalize(_overrideLocale) : _activeLocaleCode;

  /// 传给 MaterialApp.router 的 localeResolutionCallback
  Locale resolveAppLocale(Locale? deviceLocale, Iterable<Locale> supportedLocales) {
    final targetCode = _normalize(_overrideLocale ?? deviceLocale);
    final matched = supportedLocales.firstWhere(
      (l) => l.languageCode.toLowerCase() == targetCode,
      orElse: () => supportedLocales.first,
    );
    _activeLocaleCode = _normalize(matched);
    return matched;
  }

  /// 供后续设置页切换语言调用：传 null 恢复跟随系统，传 Locale('zh') / Locale('en') 手动指定
  void setLocale(Locale? locale) {
    if (_overrideLocale == locale) return;
    _overrideLocale = locale;
    _activeLocaleCode = _normalize(locale ?? PlatformDispatcher.instance.locale);
    notifyListeners();
  }

  static String _normalize(Locale? locale) {
    return locale?.languageCode.toLowerCase() == 'zh' ? 'zh' : 'en';
  }
}
