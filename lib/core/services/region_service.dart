import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fullxpet/common/config/app_config.dart';
import 'package:fullxpet/common/models/country_dto.dart';
import 'package:fullxpet/core/network/api_endpoints.dart';
import 'package:fullxpet/core/network/http_client.dart';
import 'package:fullxpet/locator.dart';

// 区域/国家服务 - 多国家、多数据中心切换
class RegionService {
  // 国家列表缓存键
  // 值类型：String（JSON数组）
  // 用途：避免每次启动都请求网络获取国家列表
  static const String _keyCountryList = 'cache_country_list';

  // 用户选中的国家代码
  // 值类型：String（如 'CN', 'US', 'HK'）
  // 用途：记住用户上次选择的国家，下次启动自动恢复
  static const String _keySelectedCountryCode = 'pref_selected_country_code';

  // 存储当前使用的API服务器地址
  // 值类型：String
  // 用途：保存当前国家的API地址，已登录用户可直接恢复，无需重新获取
  static const String _keyCurrentBaseUrl = 'pref_current_api_base_url';

  List<CountryDto> _countries = [];
  CountryDto? _currentCountry;
  String _currentApiBaseUrl = '';

  final Map<String, String> _dcUrlCache = {};

  List<CountryDto> get countries => _countries;
  CountryDto? get currentCountry => _currentCountry;
  String get currentApiBaseUrl => _currentApiBaseUrl;

  // 默认兜底国家（防止极端断网情况列表完全为空）
  static final List<CountryDto> _fallbackCountries = [
    CountryDto(
      name: '中国',
      countryCode: 'CN',
      phoneCountryCode: '+86',
      defaultDataRegion: 'CN',
      defaultDataCenter: 'CN',
    ),
    CountryDto(
      name: 'United States',
      countryCode: 'US',
      phoneCountryCode: '+1',
      defaultDataRegion: 'US',
      defaultDataCenter: 'US',
    ),
    CountryDto(
      name: '中国香港',
      countryCode: 'HK',
      phoneCountryCode: '+852',
      defaultDataRegion: 'CN',
      defaultDataCenter: 'CN',
    ),
  ];

  Future<void> initBootstrap({required bool isLoggedIn}) async {
    final prefs = await SharedPreferences.getInstance();

    if (isLoggedIn) {
      final savedBaseUrl = prefs.getString(_keyCurrentBaseUrl);
      if (savedBaseUrl != null && savedBaseUrl.isNotEmpty) {
        _currentApiBaseUrl = savedBaseUrl;
        locator<HttpClient>().init(baseUrl: _currentApiBaseUrl);
        // 后台静默预热国家列表，不阻塞进入主页
        loadCountryList();
        return;
      }
    }

    await loadCountryList();

    final savedCode = prefs.getString(_keySelectedCountryCode);
    if (savedCode != null && _countries.any((c) => c.countryCode == savedCode)) {
      _currentCountry = _countries.firstWhere((c) => c.countryCode == savedCode);
    } else {
      _currentCountry = _matchDefaultCountryBySystem();
    }

    final countryCode = _currentCountry?.countryCode ?? 'CN';
    await switchCountryByCode(countryCode);
  }

  Future<List<CountryDto>> loadCountryList() async {
    //  如果内存已有，直接返回
    if (_countries.isNotEmpty) return _countries;

    //  读本地落盘缓存
    final prefs = await SharedPreferences.getInstance();
    final cachedStr = prefs.getString(_keyCountryList);

    if (cachedStr != null && cachedStr.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(cachedStr);
        _countries = list.map((e) => CountryDto.fromJson(e)).toList();
        if (_countries.isNotEmpty) return _countries;
      } catch (_) {}
    }

    //  网络拉取
    try {
      final config = AppConfig.prod();
      final tempClient = HttpClient();
      tempClient.init(baseUrl: config.baseUrl);

      final currentLocale = ui.PlatformDispatcher.instance.locale;
      final localeParam = currentLocale.languageCode.toLowerCase() == 'zh' ? 'zh-CN' : 'en-US';

      final res = await tempClient.get<Map<String, dynamic>>(
        ApiEndpoints.countries,
        query: {'locale': localeParam, 'clientAppId': 'fullxpet'},
      );

      if (res.data != null && (res.code == 0 || res.code == 200)) {
        final List<dynamic> items = res.data!['items'] ?? [];
        _countries = items.map((e) => CountryDto.fromJson(e)).toList();
        await prefs.setString(_keyCountryList, jsonEncode(items));
      }
    } catch (e) {
      debugPrint("Fetch Country List Error: $e");
    }

    //  网络失败时兜底，确保绝对不为空
    if (_countries.isEmpty) {
      _countries = List.from(_fallbackCountries);
    }

    return _countries;
  }

  Future<bool> switchCountry(CountryDto country) async {
    final previousCountry = _currentCountry;
    _currentCountry = country;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedCountryCode, country.countryCode);

    final success = await switchCountryByCode(country.countryCode);
    if (!success) {
      _currentCountry = previousCountry;
      return false;
    }
    return true;
  }

  Future<bool> switchCountryByCode(String countryCode) async {
    final prefs = await SharedPreferences.getInstance();

    if (_dcUrlCache.containsKey(countryCode)) {
      _currentApiBaseUrl = _dcUrlCache[countryCode]!;
      locator<HttpClient>().init(baseUrl: _currentApiBaseUrl);
      await prefs.setString(_keyCurrentBaseUrl, _currentApiBaseUrl);
      return true;
    }

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
          _dcUrlCache[countryCode] = _currentApiBaseUrl;
          locator<HttpClient>().init(baseUrl: _currentApiBaseUrl);
          await prefs.setString(_keyCurrentBaseUrl, _currentApiBaseUrl);
          return true;
        }
      }
    } catch (e) {
      debugPrint("Switch Country / DC Error: $e");
    }
    return false;
  }

  CountryDto _matchDefaultCountryBySystem() {
    final systemLocale = ui.PlatformDispatcher.instance.locale;
    final sysCountryCode = systemLocale.countryCode?.toUpperCase() ?? 'CN';

    return _countries.firstWhere(
      (c) => c.countryCode.toUpperCase() == sysCountryCode,
      orElse: () => _countries.isNotEmpty
          ? _countries.firstWhere((c) => c.countryCode == 'CN', orElse: () => _countries.first)
          : _fallbackCountries.first,
    );
  }
}
