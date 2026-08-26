import 'package:flutter/material.dart';
import 'package:fullxpet/core/utils/device_batch_helper.dart';
import 'package:fullxpet/locator.dart';
import 'package:fullxpet/app.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  //确保引擎已绑定
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // 保持原生启动图
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // 初始化时区数据
  tz_data.initializeTimeZones();

  // 注册 GetIt 依赖注入容器
  setupLocator();

  // 设备批次映射数据预加载
  try {
    await DeviceBatchHelper().init();
  } catch (e) {
    debugPrint("设备ID映射初始化失败: $e");
  }

  // 挂载 UI 树
  runApp(const MyApp());
}
