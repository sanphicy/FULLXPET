import 'package:get_it/get_it.dart';
import 'package:fullxpet/core/hardware/mqtt_manager.dart';
import 'package:fullxpet/core/network/http_client.dart';
import 'package:fullxpet/core/services/region_service.dart';
import 'package:fullxpet/core/hardware/bluetooth_manager.dart';

import 'package:fullxpet/features/device/device_provider.dart';
import 'package:fullxpet/features/device/active_device_provider.dart';
import 'package:fullxpet/features/device/repositories/device_repository.dart';
import 'package:fullxpet/features/auth/repositories/auth_repository.dart';

import 'package:fullxpet/features/user/viewmodels/user_view_model.dart';

final locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton<HttpClient>(() => HttpClient());
  // 注册蓝牙管理器并执行自初始化
  locator.registerLazySingleton<BluetoothManager>(
    () => BluetoothManager()..init(),
  );
  // mqtt
  locator.registerLazySingleton<MqttManager>(() => MqttManager());

  // 仓库
  locator.registerLazySingleton<AuthRepository>(() => AuthRepository());
  locator.registerLazySingleton<DeviceRepository>(() => DeviceRepository());

  // 全局状态
  locator.registerLazySingleton<UserProvider>(() => UserProvider());
  locator.registerLazySingleton<DeviceProvider>(() => DeviceProvider());
  locator.registerLazySingleton<ActiveDeviceProvider>(
    () => ActiveDeviceProvider(),
  );

  // 请求信息
  locator.registerLazySingleton<RegionService>(() => RegionService());
}
