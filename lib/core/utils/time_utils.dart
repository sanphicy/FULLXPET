import 'package:timezone/timezone.dart' as tz;

// 时间与时区通用转换工具类
class TimeUtils {
  TimeUtils._();

  // 将 "HH:mm" 格式时间字符串转换为当日总秒数 (如 "08:00" -> 28800)
  static int timeToSeconds(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 3600 + m * 60;
  }

  // 将秒数转换为 "HH:mm" 格式时间字符串 (如 28800 -> "08:00")
  static String secondsToTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  // 根据时区标识（如 "Asia/Shanghai"）计算格式化 UTC 偏移字符串 (如 "UTC+08:00")
  static String calculateOffsetStr(String tzName) {
    try {
      final location = tz.getLocation(tzName);
      final offset = tz.TZDateTime.now(location).timeZoneOffset;
      final hours = offset.inHours;
      final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
      final sign = hours >= 0 ? '+' : '-';
      return 'UTC$sign${hours.abs().toString().padLeft(2, '0')}:$minutes';
    } catch (_) {
      return 'UTC+00:00';
    }
  }
}
