import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/core/navigation/nav_service.dart';
import 'package:fullxpet/shell/main_shell.dart';
import 'package:fullxpet/locator.dart';

//splash
import 'package:fullxpet/features/splash/splash_page.dart';

// auth
import 'package:fullxpet/features/auth/page/login_page.dart';
import 'package:fullxpet/features/auth/page/register_page.dart';
import 'package:fullxpet/features/auth/page/forgot_password_page.dart';
import 'package:fullxpet/features/auth/auth_provider.dart';

// device
import 'package:fullxpet/features/device/device_provider.dart';
import 'package:fullxpet/features/device/device_manager/device_manager_page.dart';
import 'package:fullxpet/features/device/device_manager/device_setting_page.dart';
import 'package:fullxpet/features/device/device_manager/timer_mode_page.dart';
import 'package:fullxpet/features/device/device_manager/wifi_info_page.dart';
import 'package:fullxpet/features/device/device_manager/weighing_calibration_page.dart';
import 'package:fullxpet/features/device/device_manager/time_zone_search_page.dart';
import 'package:fullxpet/features/device/device_add/device_add_provider.dart';
import 'package:fullxpet/features/device/device_add/pages/device_add_success_page.dart';
import 'package:fullxpet/features/device/device_add/pages/device_add_search_page.dart';
import 'package:fullxpet/features/device/device_add/pages/device_add_wifi_page.dart';
import 'package:fullxpet/features/device/device_add/models/discovered_device.dart';
import 'package:fullxpet/features/device/device_usage/device_usage_provider.dart';
import 'package:fullxpet/features/device/active_device_provider.dart';

// user
import 'package:fullxpet/features/user/user_provider.dart';
import 'package:fullxpet/features/user/personal_info_page.dart';
import 'package:fullxpet/features/user/about_us_page.dart';
import 'package:fullxpet/features/user/feedback_page.dart';

class AppRoutes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot_password';
  static const home = '/home';
  static const deviceManager = '/device_manager/:id';
  static const deviceSetting = '/device_setting/:id';
  static const timezone = '/device_setting/:id/timezone';
  static const deviceTimer = '/device_setting/:id/timer';
  static const deviceWifi = '/device_setting/:id/wifi';
  static const deviceWeighing = '/device_setting/:id/weighing';
  static const deviceAddSearch = '/device-add-search';
  static const deviceAddWifi = '/device-add-wifi';
  static const deviceAddSuccess = '/device-add-success/:id';
  static const personalInfo = '/personal_info';
  static const String aboutUs = '/about_us';
  static const String feedback = '/feedback';
}

class AppRouter {
  static late final GoRouter router;

  static final List<GoRoute> _splashRoutes = [
    GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashPage()),
    GoRoute(path: AppRoutes.welcome, builder: (context, state) => const WelcomePage()),
  ];

  static final List<GoRoute> _authRoutes = [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => ChangeNotifierProvider(create: (_) => LoginProvider(), child: const LoginPage()),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => ChangeNotifierProvider(create: (_) => LoginProvider(), child: const RegisterPage()),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (context, state) =>
          ChangeNotifierProvider(create: (_) => LoginProvider(), child: const ForgotPasswordPage()),
    ),
  ];

  static final List<GoRoute> _homeRoutes = [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DeviceProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()..fetchUserInfo()),
          ChangeNotifierProvider(create: (_) => DeviceUsageProvider()..selectDevice(0)),
        ],
        child: const MainShell(),
      ),
    ),
  ];

  static final List<GoRoute> _deviceRoutes = [
    GoRoute(
      path: AppRoutes.deviceManager,
      builder: (context, state) {
        final String deviceId = state.pathParameters['id'] ?? '';
        // 触发全局设备切换
        locator<ActiveDeviceProvider>().selectDevice(deviceId);

        // 核心修复：使用 .value 将单例挂载到组件树，允许页面 watch
        return ChangeNotifierProvider<ActiveDeviceProvider>.value(
          value: locator<ActiveDeviceProvider>(),
          child: DeviceManagerPage(deviceId: deviceId),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.deviceSetting,
      builder: (context, state) {
        final String deviceId = state.pathParameters['id'] ?? '';
        return ChangeNotifierProvider<ActiveDeviceProvider>.value(
          value: locator<ActiveDeviceProvider>(),
          child: DeviceSettingPage(deviceId: deviceId),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.timezone,
      builder: (context, state) => ChangeNotifierProvider<ActiveDeviceProvider>.value(
        value: locator<ActiveDeviceProvider>(),
        child: const TimeZoneSearchPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.deviceTimer,
      builder: (context, state) => ChangeNotifierProvider<ActiveDeviceProvider>.value(
        value: locator<ActiveDeviceProvider>(),
        child: const TimerModePage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.deviceWifi,
      builder: (context, state) => ChangeNotifierProvider<ActiveDeviceProvider>.value(
        value: locator<ActiveDeviceProvider>(),
        child: const WifiInfoPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.deviceWeighing,
      builder: (context, state) => ChangeNotifierProvider<ActiveDeviceProvider>.value(
        value: locator<ActiveDeviceProvider>(),
        child: const WeighingCalibrationPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.deviceAddSearch,
      builder: (context, state) =>
          ChangeNotifierProvider(create: (_) => DeviceAddProvider(), child: const DeviceAddSearchPage()),
    ),
    GoRoute(
      path: AppRoutes.deviceAddWifi,
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>;
        return ChangeNotifierProvider.value(
          value: args['provider'] as DeviceAddProvider,
          child: DeviceAddWifiPage(targetDevice: args['device'] as DiscoveredDevice),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.deviceAddSuccess,
      builder: (context, state) {
        final String deviceId = state.pathParameters['id'] ?? '';
        return DeviceAddSuccessPage(deviceId: deviceId);
      },
    ),
  ];

  static final List<GoRoute> _userRoutes = [
    GoRoute(
      path: AppRoutes.personalInfo,
      builder: (context, state) =>
          ChangeNotifierProvider.value(value: state.extra as UserProvider, child: const PersonalInfoPage()),
    ),
    GoRoute(path: AppRoutes.aboutUs, builder: (context, state) => const AboutUsPage()),
    GoRoute(path: AppRoutes.feedback, builder: (context, state) => const FeedbackPage()),
  ];

  static void setup(String initialRoute) {
    router = GoRouter(
      navigatorKey: NavService.rootNavigatorKey,
      initialLocation: initialRoute,
      routes: [..._splashRoutes, ..._authRoutes, ..._homeRoutes, ..._deviceRoutes, ..._userRoutes],
    );
  }
}
