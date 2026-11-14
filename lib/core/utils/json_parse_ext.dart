/// JSON 解析扩展，提供对 `Map` 的安全取值方法
extension JsonParseExt on Map<dynamic, dynamic>? {
  /// 获取字符串值
  ///
  /// 值为 `null`、空字符串或字符串 `"null"` 时返回 [defaultValue]。
  String getStr(String key, {String defaultValue = ''}) {
    final map = this;
    if (map == null) return defaultValue;
    final value = map[key];
    if (value == null) return defaultValue;
    final str = value.toString().trim();
    return (str.isEmpty || str == 'null') ? defaultValue : str;
  }

  /// 获取可空字符串值
  ///
  /// 值为 `null`、空字符串或字符串 `"null"` 时返回 `null`。
  String? getNullableStr(String key) {
    final map = this;
    if (map == null) return null;
    final value = map[key];
    if (value == null) return null;
    final str = value.toString().trim();
    return (str.isEmpty || str == 'null') ? null : str;
  }

  /// 获取布尔值
  ///
  /// 兼容 `bool`、数字（`0` 为 `false`，非 `0` 为 `true`）以及
  /// 字符串 `"true"`/`"1"`/`"false"`/`"0"`；无法识别时返回 [defaultValue]。
  bool getBool(String key, {bool defaultValue = false}) {
    final map = this;
    if (map == null) return defaultValue;
    final value = map[key];
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final str = value.toString().trim().toLowerCase();
    if (str == 'true' || str == '1') return true;
    if (str == 'false' || str == '0') return false;
    return defaultValue;
  }

  /// 获取整数值
  ///
  /// 兼容 `int`、`num` 及可解析的数字字符串；解析失败时返回 [defaultValue]。
  int getInt(String key, {int defaultValue = 0}) {
    final map = this;
    if (map == null) return defaultValue;
    final value = map[key];
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    final str = value.toString().trim();
    return int.tryParse(str) ?? double.tryParse(str)?.toInt() ?? defaultValue;
  }

  /// 获取可空整数值
  ///
  /// 兼容 `int`、`num` 及可解析的数字字符串；解析失败时返回 `null`。
  int? getNullableInt(String key) {
    final map = this;
    if (map == null) return null;
    final value = map[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    final str = value.toString().trim();
    return int.tryParse(str) ?? double.tryParse(str)?.toInt();
  }

  /// 获取浮点数值
  ///
  /// 兼容 `double`、`num` 及可解析的数字字符串；解析失败时返回 [defaultValue]。
  double getDouble(String key, {double defaultValue = 0.0}) {
    final map = this;
    if (map == null) return defaultValue;
    final value = map[key];
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim()) ?? defaultValue;
  }

  /// 获取 Map 值
  ///
  /// 自动将 `Map<dynamic, dynamic>` 的键转为 `String`；
  /// 值不是 Map 时返回 `null`。
  Map<String, dynamic>? getMap(String key) {
    final map = this;
    if (map == null) return null;
    final value = map[key];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  /// 获取列表值
  ///
  /// 值不是 List 时返回空列表。
  List<dynamic> getList(String key) {
    final map = this;
    if (map == null) return const [];
    final value = map[key];
    return value is List ? value : const [];
  }

  /// 获取字符串列表值
  ///
  /// 元素统一 `toString` 并去除首尾空白，过滤空字符串；无有效元素时返回空列表。
  List<String> getStrList(String key) {
    final list = getList(key);
    if (list.isEmpty) return const [];
    return list.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
  }
}
