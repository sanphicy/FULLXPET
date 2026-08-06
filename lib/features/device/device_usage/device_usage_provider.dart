import 'package:fullxpet/locator.dart';
import 'package:fullxpet/core/network/http_client.dart';
import 'package:fullxpet/core/network/api_endpoints.dart';
import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/features/device/models/device_dto.dart';

class DailyUsageData {
  final DateTime date;
  final String weekDay;
  final String dayStr;
  int times;
  int duration;

  DailyUsageData({required this.date, required this.weekDay, required this.dayStr, this.times = 0, this.duration = 0});
}

class DeviceUsageProvider extends BaseProvider {
  final HttpClient _httpClient = locator<HttpClient>();

  int _selectedDeviceIndex = 0;
  int _selectedDayIndex = 6;

  List<DeviceDto> _deviceList = [];
  List<DailyUsageData> _weekDays = [];

  int get selectedDeviceIndex => _selectedDeviceIndex;
  int get selectedDayIndex => _selectedDayIndex;
  List<DeviceDto> get deviceList => _deviceList;
  List<DailyUsageData> get weekDays => _weekDays;

  DailyUsageData? get selectedDayData =>
      _weekDays.isNotEmpty && _selectedDayIndex < _weekDays.length ? _weekDays[_selectedDayIndex] : null;

  void syncDevices(List<DeviceDto> devices) {
    _deviceList = devices;
    if (_selectedDeviceIndex >= _deviceList.length) {
      _selectedDeviceIndex = 0;
    }
    _generateRecent7Days();
    if (_deviceList.isNotEmpty) {
      fetchDeviceUsageLogs();
    } else {
      notifyListeners();
    }
  }

  void selectDevice(int index) {
    if (_selectedDeviceIndex == index || index >= _deviceList.length) return;
    _selectedDeviceIndex = index;
    _generateRecent7Days();
    fetchDeviceUsageLogs();
  }

  void selectDay(int index) {
    if (_selectedDayIndex == index) return;
    _selectedDayIndex = index;
    notifyListeners();
  }

  void _generateRecent7Days() {
    final now = DateTime.now();
    const weekDayMap = {1: '周一', 2: '周二', 3: '周三', 4: '周四', 5: '周五', 6: '周六', 7: '周日'};

    _weekDays = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DailyUsageData(date: d, weekDay: weekDayMap[d.weekday] ?? '', dayStr: d.day.toString());
    });
    _selectedDayIndex = 6;
  }

  Future<void> fetchDeviceUsageLogs() async {
    if (_deviceList.isEmpty) return;

    final deviceId = _deviceList[_selectedDeviceIndex].deviceId;
    if (deviceId.isEmpty) return;

    setLoading(true);
    clearError();

    try {
      final now = DateTime.now();
      final fromDate = now.subtract(const Duration(days: 7)).toUtc();
      final toDate = now.toUtc();

      final fromStr = "${fromDate.toIso8601String().split('.').first}Z";
      final toStr = "${toDate.toIso8601String().split('.').first}Z";

      final query = {"from": fromStr, "to": toStr, "dpid": "207,208", "pageSize": "100", "sort": "asc"};

      final result = await _httpClient.get<Map<String, dynamic>>(ApiEndpoints.deviceLogs(deviceId), query: query);

      if (result.data != null) {
        final List<dynamic> items = result.data!['items'] ?? [];

        for (var item in items) {
          final String tsStr = item['ts'] ?? '';
          final List<dynamic> values = item['values'] ?? [];
          if (tsStr.isEmpty || values.isEmpty) continue;

          final logTime = DateTime.parse(tsStr).toLocal();

          for (var dayData in _weekDays) {
            if (logTime.year == dayData.date.year &&
                logTime.month == dayData.date.month &&
                logTime.day == dayData.date.day) {
              for (var valObj in values) {
                final dpid = valObj['dpid']?.toString();
                final val = int.tryParse(valObj['value']?.toString() ?? '0') ?? 0;

                if (dpid == '207') {
                  dayData.times = val;
                } else if (dpid == '208') {
                  dayData.duration = val;
                }
              }
            }
          }
        }
      }
    } catch (e) {
      setError("网络请求失败，请稍后重试");
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }
}
