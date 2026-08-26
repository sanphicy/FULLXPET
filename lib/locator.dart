import 'package:get_it/get_it.dart';
import 'package:fullxpet/core/hardware/mqtt_manager.dart';
import 'package:fullxpet/core/network/http_client.dart';
import 'package:fullxpet/core/services/region_service.dart';
import 'package:fullxpet/core/hardware/bluetooth_manager.dart';

import 'package:fullxpet/features/device/device_provider.dart';
import 'package:fullxpet/features/device/active_device_provider.dart';
import 'package:fullxpet/features/device/repositories/device_repository.dart';
import 'package:fullxpet/features/auth/repositories/auth_repository.dart';

import 'package:fullxpet/features/user/providers/user_provider.dart';
import 'package:fullxpet/common/config/app_config.dart';
import 'package:fullxpet/core/storage/token_manager.dart';

final locator = GetIt.instance;

void setupLocator({AppConfig? config}) {
  final appConfig = config ?? AppConfig.prod();
  TokenManager.init(accessKey: appConfig.accessTokenKey);
  //注册app配置
  locator.registerSingleton<AppConfig>(appConfig);
  // 注册时直接配置 BaseUrl，随用随有
  locator.registerLazySingleton<HttpClient>(() => HttpClient()..init(baseUrl: appConfig.baseUrl));

  // 注册蓝牙管理器并执行自初始化
  locator.registerLazySingleton<BluetoothManager>(() => BluetoothManager()..init());
  // mqtt
  locator.registerLazySingleton<MqttManager>(() => MqttManager());

  // 仓库
  locator.registerLazySingleton<AuthRepository>(() => AuthRepository());
  locator.registerLazySingleton<DeviceRepository>(() => DeviceRepository());

  // 全局状态
  locator.registerLazySingleton<UserProvider>(() => UserProvider());
  locator.registerLazySingleton<DeviceProvider>(() => DeviceProvider());
  locator.registerLazySingleton<ActiveDeviceProvider>(() => ActiveDeviceProvider());

  // 请求信息
  locator.registerLazySingleton<RegionService>(() => RegionService());
}
