import 'package:flutter/material.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/core/network/api_endpoints.dart';
import 'package:fullxpet/core/network/http_client.dart';
import 'package:fullxpet/features/device/models/device_dto.dart';
import 'package:fullxpet/locator.dart';

class DailyUsageData {
  final DateTime date;
  final int weekdayIndex;
  final String dayStr;
  int times;
  int duration;

  DailyUsageData({
    required this.date,
    required this.weekdayIndex,
    required this.dayStr,
    this.times = 0,
    this.duration = 0,
  });

  String getWeekdayName(S s) {
    switch (weekdayIndex) {
      case 1:
        return s.mon;
      case 2:
        return s.tue;
      case 3:
        return s.wed;
      case 4:
        return s.thu;
      case 5:
        return s.fri;
      case 6:
        return s.sat;
      case 7:
        return s.sun;
      default:
        return '';
    }
  }
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
    _weekDays = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DailyUsageData(date: d, weekdayIndex: d.weekday, dayStr: d.day.toString());
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
    } catch (_) {
      setError("网络请求失败，请稍后重试");
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }
}
