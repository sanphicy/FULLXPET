import 'dart:convert';
import 'package:flutter/services.dart';

class DeviceBatchHelper {
  static final DeviceBatchHelper _instance = DeviceBatchHelper._internal();
  factory DeviceBatchHelper() => _instance;
  DeviceBatchHelper._internal();

  Map<String, String> _mappingMap = {};

  /// App 启动时预加载映射表到内存
  Future<void> init() async {
    if (_mappingMap.isNotEmpty) return;
    try {
      final jsonString = await rootBundle.loadString('assets/data/device_batch_mapping.json');
      final Map<String, dynamic> rawMap = jsonDecode(jsonString);

      // 转为 Map<String, String>
      _mappingMap = rawMap.map((key, value) => MapEntry(key.toString(), value.toString()));
    } catch (e) {
      print("⚠️ 加载批次映射表失败: $e");
    }
  }

  /// 根据第三方设备 ID 匹配美观的批次号，查不到则用原 ID 兜底
  String getDisplayBatchNo(String deviceId) {
    return _mappingMap[deviceId] ?? deviceId;
  }
}
