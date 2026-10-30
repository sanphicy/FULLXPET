extension JsonParseExt on Map<String, dynamic> {
  String getStr(String key, {String defaultValue = ''}) {
    final value = this[key];
    if (value == null) return defaultValue;
    final str = value.toString().trim();
    return str.isEmpty ? defaultValue : str;
  }
}
