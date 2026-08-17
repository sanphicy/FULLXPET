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

  // 内存缓存各国家对应的 apiBaseUrl，避免重复请求
  final Map<String, String> _dcUrlCache = {};

  List<CountryDto> get countries => _countries;
  CountryDto? get currentCountry => _currentCountry;
  String get currentApiBaseUrl => _currentApiBaseUrl;

  Future<void> initBootstrap({required bool isLoggedIn}) async {
    final prefs = await SharedPreferences.getInstance();

    if (isLoggedIn) {
      final savedBaseUrl = prefs.getString(_keyCurrentBaseUrl);
      if (savedBaseUrl != null && savedBaseUrl.isNotEmpty) {
        _currentApiBaseUrl = savedBaseUrl;
        locator<HttpClient>().init(baseUrl: _currentApiBaseUrl);
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
    final prefs = await SharedPreferences.getInstance();
    final cachedStr = prefs.getString(_keyCountryList);

    if (cachedStr != null && cachedStr.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(cachedStr);
        _countries = list.map((e) => CountryDto.fromJson(e)).toList();
        if (_countries.isNotEmpty) return _countries;
      } catch (_) {}
    }

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

  /// 乐观切换国家：先改当前实体，再后台同步 BaseURL
  Future<bool> switchCountry(CountryDto country) async {
    final previousCountry = _currentCountry;
    _currentCountry = country;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedCountryCode, country.countryCode);

    final success = await switchCountryByCode(country.countryCode);
    if (!success) {
      // 切换失败回退
      _currentCountry = previousCountry;
      return false;
    }
    return true;
  }

  /// 根据 CountryCode 解析并配置 BaseURL（带内存缓存加速）
  Future<bool> switchCountryByCode(String countryCode) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 优先命中内存缓存，直接秒切
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

          // 写入内存缓存
          _dcUrlCache[countryCode] = _currentApiBaseUrl;

          // 热更新全局网络客户端 BaseUrl
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
