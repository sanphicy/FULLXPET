import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/core/navigation/nav_service.dart';
import 'package:fullxpet/shell/main_shell.dart';
import 'package:fullxpet/locator.dart';

// splash
import 'package:fullxpet/features/splash/splash_page.dart';
import 'package:fullxpet/features/splash/welcome_page.dart';

// auth
import 'package:fullxpet/features/auth/page/login_page.dart';
import 'package:fullxpet/features/auth/page/register_page.dart';
import 'package:fullxpet/features/auth/page/forgot_password_page.dart';
import 'package:fullxpet/features/auth/viewmodels/login_view_model.dart';
import 'package:fullxpet/features/auth/viewmodels/register_view_model.dart';
import 'package:fullxpet/features/auth/viewmodels/forgot_password_view_model.dart';

// home tabs
import 'package:fullxpet/features/device/device_list/device_list_page.dart';
import 'package:fullxpet/features/device/device_usage/device_usage_page.dart';
import 'package:fullxpet/features/device/device_usage/device_usage_provider.dart';
import 'package:fullxpet/features/user/user_page.dart';

// device
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
import 'package:fullxpet/features/device/active_device_provider.dart';

// user
import 'package:fullxpet/features/user/personal_info_page.dart';
import 'package:fullxpet/features/user/about_us_page.dart';
import 'package:fullxpet/features/user/feedback_page.dart';

// other
import 'package:fullxpet/common/widgets/web_view_page.dart';

class AppRoutes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot_password';

  // Shell Tabs
  static const home = '/home';
  static const tabDevice = '/home/device';
  static const tabUsage = '/home/usage';
  static const tabUser = '/home/user';

  // Device Detail
  static const deviceManager = '/device_manager/:id';
  static const deviceSetting = '/device_setting/:id';
  static const timezone = '/device_setting/:id/timezone';
  static const deviceTimer = '/device_setting/:id/timer';
  static const deviceWifi = '/device_setting/:id/wifi';
  static const deviceWeighing = '/device_setting/:id/weighing';
  static const deviceAddSearch = '/device-add-search';
  static const deviceAddWifi = '/device-add-wifi';
  static const deviceAddSuccess = '/device-add-success/:id';

  // User
  static const personalInfo = '/personal_info';
  static const String aboutUs = '/about_us';
  static const String feedback = '/feedback';
  static const webView = '/web_view';
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
      builder: (context, state) => ChangeNotifierProvider(create: (_) => LoginViewModel(), child: const LoginPage()),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) =>
          ChangeNotifierProvider(create: (_) => RegisterViewModel(), child: const RegisterPage()),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (context, state) =>
          ChangeNotifierProvider(create: (_) => ForgotPasswordViewModel(), child: const ForgotPasswordPage()),
    ),
  ];

  // 使用 StatefulShellRoute 管理底部三大 Tab
  static final StatefulShellRoute _homeShellRoute = StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) {
      return MainShell(navigationShell: navigationShell);
    },
    branches: [
      // Branch 1: 设备列表
      StatefulShellBranch(
        routes: [
          GoRoute(path: AppRoutes.home, redirect: (_, __) => AppRoutes.tabDevice),
          GoRoute(path: AppRoutes.tabDevice, builder: (context, state) => const DeviceListPage()),
        ],
      ),
      // Branch 2: 使用数据统计
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.tabUsage,
            builder: (context, state) => ChangeNotifierProvider(
              create: (_) => DeviceUsageProvider()..selectDevice(0),
              child: const DeviceUsagePage(),
            ),
          ),
        ],
      ),
      // Branch 3: 我的个人中心
      StatefulShellBranch(
        routes: [GoRoute(path: AppRoutes.tabUser, builder: (context, state) => const UserPage())],
      ),
    ],
  );

  static final List<GoRoute> _deviceRoutes = [
    GoRoute(
      path: AppRoutes.deviceManager,
      builder: (context, state) {
        final String deviceId = state.pathParameters['id'] ?? '';
        locator<ActiveDeviceProvider>().selectDevice(deviceId);
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
        final args = state.extra as Map<String, dynamic>? ?? {};
        final provider = args['provider'] as DeviceAddProvider?;
        final device = args['device'] as DiscoveredDevice?;
        if (provider == null || device == null) {
          return const Scaffold(body: Center(child: Text("参数异常")));
        }
        return ChangeNotifierProvider.value(
          value: provider,
          child: DeviceAddWifiPage(targetDevice: device),
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
      // 这里的 UserProvider 已在全局根树挂载，直接进入页面消费即可，无需再从 extra 强转
      builder: (context, state) => const PersonalInfoPage(),
    ),
    GoRoute(path: AppRoutes.aboutUs, builder: (context, state) => const AboutUsPage()),
    GoRoute(path: AppRoutes.feedback, builder: (context, state) => const FeedbackPage()),
  ];

  static final List<GoRoute> _commonRoutes = [
    GoRoute(
      path: AppRoutes.webView,
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>? ?? {};
        final title = args['title'] ?? '网页链接';
        final url = args['url'] ?? 'https://www.google.com';
        return WebViewPage(title: title, url: url);
      },
    ),
  ];

  static void setup(String initialRoute) {
    router = GoRouter(
      navigatorKey: NavService.rootNavigatorKey,
      initialLocation: initialRoute,
      routes: [..._splashRoutes, ..._authRoutes, _homeShellRoute, ..._deviceRoutes, ..._userRoutes, ..._commonRoutes],
    );
  }
}
