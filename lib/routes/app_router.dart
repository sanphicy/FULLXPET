import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:fullxpet/common/widgets/web_view_page.dart';
import 'package:fullxpet/core/services/nav_service.dart';
import 'package:fullxpet/locator.dart';

// Splash
import 'package:fullxpet/features/splash/pages/splash_page.dart';
import 'package:fullxpet/features/splash/pages/welcome_page.dart';

// Auth
import 'package:fullxpet/features/auth/page/forgot_password_page.dart';
import 'package:fullxpet/features/auth/page/login_page.dart';
import 'package:fullxpet/features/auth/page/register_page.dart';
import 'package:fullxpet/features/auth/viewmodels/forgot_password_view_model.dart';
import 'package:fullxpet/features/auth/viewmodels/login_view_model.dart';
import 'package:fullxpet/features/auth/viewmodels/register_view_model.dart';

// Home Shell & Tabs
import 'package:fullxpet/features/home/home_shell_page.dart';
import 'package:fullxpet/features/device/device_list/device_list_page.dart';
import 'package:fullxpet/features/device/device_usage/device_usage_page.dart';
import 'package:fullxpet/features/device/device_usage/device_usage_provider.dart';
import 'package:fullxpet/features/user/pages/user_page.dart';

// Device
import 'package:fullxpet/features/device/active_device_provider.dart';
import 'package:fullxpet/features/device/device_add/device_add_provider.dart';
import 'package:fullxpet/features/device/device_add/models/discovered_device.dart';
import 'package:fullxpet/features/device/device_add/pages/device_add_search_page.dart';
import 'package:fullxpet/features/device/device_add/pages/device_add_success_page.dart';
import 'package:fullxpet/features/device/device_add/pages/device_add_wifi_page.dart';
import 'package:fullxpet/features/device/device_manager/device_manager_page.dart';
import 'package:fullxpet/features/device/device_manager/device_setting_page.dart';
import 'package:fullxpet/features/device/device_manager/time_zone_search_page.dart';
import 'package:fullxpet/features/device/device_manager/timer_mode_page.dart';
import 'package:fullxpet/features/device/device_manager/weighing_calibration_page.dart';
import 'package:fullxpet/features/device/device_manager/wifi_info_page.dart';

// User
import 'package:fullxpet/features/user/pages/about_us_page.dart';
import 'package:fullxpet/features/user/pages/feedback_page.dart';
import 'package:fullxpet/features/user/pages/personal_info_page.dart';

class AppRoutes {
  // Splash & Auth
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

  // Device Detail (路径声明)
  static const deviceManager = '/device_manager/:id';
  static const deviceSetting = '/device_setting/:id';
  static const timezone = '/device_setting/:id/timezone';
  static const deviceTimer = '/device_setting/:id/timer';
  static const deviceWifi = '/device_setting/:id/wifi';
  static const deviceWeighing = '/device_setting/:id/weighing';
  static const deviceAddSearch = '/device_add_search';
  static const deviceAddWifi = '/device_add_wifi';
  static const deviceAddSuccess = '/device_add_success/:id';

  // Device Detail (跳转辅助方法 - 业务代码直接调，避免手写字符串)
  static String deviceManagerPath(String id) => '/device_manager/$id';
  static String deviceSettingPath(String id) => '/device_setting/$id';
  static String timezonePath(String id) => '/device_setting/$id/timezone';
  static String deviceTimerPath(String id) => '/device_setting/$id/timer';
  static String deviceWifiPath(String id) => '/device_setting/$id/wifi';
  static String deviceWeighingPath(String id) => '/device_setting/$id/weighing';
  static String deviceAddSuccessPath(String id) => '/device_add_success/$id';

  // User & Common
  static const personalInfo = '/personal_info';
  static const aboutUs = '/about_us';
  static const feedback = '/feedback';
  static const webView = '/web_view';
}

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: NavService.rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    routes: [..._splashRoutes, ..._authRoutes, _homeShellRoute, ..._deviceRoutes, ..._userRoutes, ..._commonRoutes],
  );

  // 统一包装 ActiveDeviceProvider 作用域
  static Widget _withActiveDevice(Widget child) {
    return ChangeNotifierProvider<ActiveDeviceProvider>.value(value: locator<ActiveDeviceProvider>(), child: child);
  }

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

  // 管理底部三大 Tab（StatefulShellRoute 自动保活）
  static final StatefulShellRoute _homeShellRoute = StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) {
      return HomeShellPage(navigationShell: navigationShell);
    },
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(path: AppRoutes.home, redirect: (_, __) => AppRoutes.tabDevice),
          GoRoute(path: AppRoutes.tabDevice, builder: (context, state) => const DeviceListPage()),
        ],
      ),
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
        return _withActiveDevice(DeviceManagerPage(deviceId: deviceId));
      },
    ),
    GoRoute(
      path: AppRoutes.deviceSetting,
      builder: (context, state) {
        final String deviceId = state.pathParameters['id'] ?? '';
        return _withActiveDevice(DeviceSettingPage(deviceId: deviceId));
      },
    ),
    GoRoute(path: AppRoutes.timezone, builder: (context, state) => _withActiveDevice(const TimeZoneSearchPage())),
    GoRoute(path: AppRoutes.deviceTimer, builder: (context, state) => _withActiveDevice(const TimerModePage())),
    GoRoute(path: AppRoutes.deviceWifi, builder: (context, state) => _withActiveDevice(const WifiInfoPage())),
    GoRoute(
      path: AppRoutes.deviceWeighing,
      builder: (context, state) => _withActiveDevice(const WeighingCalibrationPage()),
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
    GoRoute(path: AppRoutes.personalInfo, builder: (context, state) => const PersonalInfoPage()),
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
}
