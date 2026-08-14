import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fullxpet/common/config/app_config.dart';
import 'package:fullxpet/common/models/country_dto.dart';
import 'package:fullxpet/core/network/api_endpoints.dart';
import 'package:fullxpet/core/network/http_client.dart';
import 'package:fullxpet/locator.dart';

class RegionService {
  static const String _keyCountryList = 'cache_country_list';
  static const String _keySelectedCountryCode = 'pref_selected_country_code';
  static const String _keyCurrentBaseUrl = 'pref_current_api_base_url';

  List<CountryDto> _countries = [];
  CountryDto? _currentCountry;
  String _currentApiBaseUrl = '';

  List<CountryDto> get countries => _countries;
  CountryDto? get currentCountry => _currentCountry;
  String get currentApiBaseUrl => _currentApiBaseUrl;

  /// 引导启动核心逻辑（供 SplashPage 调用）
  Future<void> initBootstrap({required bool isLoggedIn}) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 如果已登录：优先使用上次绑定的数据中心地址
    if (isLoggedIn) {
      final savedBaseUrl = prefs.getString(_keyCurrentBaseUrl);
      if (savedBaseUrl != null && savedBaseUrl.isNotEmpty) {
        _currentApiBaseUrl = savedBaseUrl;
        locator<HttpClient>().init(baseUrl: _currentApiBaseUrl);
        return;
      }
    }

    // 2. 未登录：准备国家列表
    await loadCountryList();

    // 3. 确定当前选中国家（优先读记住的选择，否则读取手机系统 Locale）
    final savedCode = prefs.getString(_keySelectedCountryCode);
    if (savedCode != null && _countries.any((c) => c.countryCode == savedCode)) {
      _currentCountry = _countries.firstWhere((c) => c.countryCode == savedCode);
    } else {
      _currentCountry = _matchDefaultCountryBySystem();
    }

    // 4. 解析并初始化该国家的 apiBaseUrl
    final countryCode = _currentCountry?.countryCode ?? 'CN';
    await switchCountryByCode(countryCode);
  }

  /// 加载国家列表（优先读本地，无本地则走 Bootstrap API 并落盘）
  Future<List<CountryDto>> loadCountryList() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedStr = prefs.getString(_keyCountryList);

    if (cachedStr != null && cachedStr.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(cachedStr);
        _countries = list.map((e) => CountryDto.fromJson(e)).toList();
        if (_countries.isNotEmpty) return _countries;
      } catch (_) {}
    }

    // 本地无缓存，通过固定 Bootstrap 基地址请求
    try {
      final config = AppConfig.prod();
      final tempClient = HttpClient();
      tempClient.init(baseUrl: config.baseUrl);

      final res = await tempClient.get<Map<String, dynamic>>(
        ApiEndpoints.countries,
        query: {'locale': 'zh-CN', 'clientAppId': 'fullxpet'},
      );

      if (res.data != null && (res.code == 0 || res.code == 200)) {
        final List<dynamic> items = res.data!['items'] ?? [];
        _countries = items.map((e) => CountryDto.fromJson(e)).toList();
        await prefs.setString(_keyCountryList, jsonEncode(items));
      }
    } catch (e) {
      debugPrint("Fetch Country List Error: $e");
    }
    return _countries;
  }

  /// 切换国家并动态更新数据中心基地址
  Future<bool> switchCountry(CountryDto country) async {
    _currentCountry = country;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedCountryCode, country.countryCode);
    return await switchCountryByCode(country.countryCode);
  }

  /// 根据 CountryCode 获取 apiBaseUrl 并热更新 HttpClient
  Future<bool> switchCountryByCode(String countryCode) async {
    final config = AppConfig.prod();
    try {
      final tempClient = HttpClient();
      tempClient.init(baseUrl: config.baseUrl);

      final payload = {"countryCode": countryCode, "clientAppId": "fullxpet"};
      final res = await tempClient.get<Map<String, dynamic>>(ApiEndpoints.mqttUri, query: payload);

      if (res.code == 0 || res.code == 200) {
        final data = res.data;
        if (data != null && data['apiBaseUrl'] != null) {
          String apiBaseUrl = data['apiBaseUrl'].toString();
          if (apiBaseUrl.endsWith('/app')) {
            apiBaseUrl = apiBaseUrl.substring(0, apiBaseUrl.length - 4);
          }
          _currentApiBaseUrl = apiBaseUrl;

          // 热更新全局网络客户端 BaseUrl 并持久化
          locator<HttpClient>().init(baseUrl: _currentApiBaseUrl);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_keyCurrentBaseUrl, _currentApiBaseUrl);
          return true;
        }
      }
    } catch (e) {
      debugPrint("Switch Country / DC Error: $e");
    }
    return false;
  }

  // 根据系统 Locale 匹配默认国家
  CountryDto _matchDefaultCountryBySystem() {
    final systemLocale = ui.PlatformDispatcher.instance.locale;
    final sysCountryCode = systemLocale.countryCode?.toUpperCase() ?? 'CN';

    return _countries.firstWhere(
      (c) => c.countryCode.toUpperCase() == sysCountryCode,
      orElse: () => _countries.isNotEmpty
          ? _countries.firstWhere((c) => c.countryCode == 'CN', orElse: () => _countries.first)
          : CountryDto(
              name: '中国',
              countryCode: 'CN',
              phoneCountryCode: '+86',
              defaultDataRegion: 'CN',
              defaultDataCenter: 'CN',
            ),
    );
  }
}
