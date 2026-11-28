import 'package:flutter/material.dart';
import 'package:fullxpet/features/pet/models/pet_dto.dart';
import 'package:fullxpet/features/pet/pages/pet_edit_page.dart';
import 'package:fullxpet/features/pet/pages/pet_list_page.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:fullxpet/common/widgets/web_view_page.dart';
import 'package:fullxpet/core/services/nav_service.dart';

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
import 'package:fullxpet/features/device/constants/product_constants.dart';
import 'package:fullxpet/features/device/device_add/device_add_provider.dart';
import 'package:fullxpet/features/device/device_add/pages/device_add_search_page.dart';
import 'package:fullxpet/features/device/device_add/pages/device_add_success_page.dart';
import 'package:fullxpet/features/device/device_add/pages/device_add_wifi_page.dart';
import 'package:fullxpet/features/device/products/litter_box/viewmodels/litter_box_viewmodel.dart';
import 'package:fullxpet/features/device/products/litter_box/pages/litter_box_manager_page.dart';
import 'package:fullxpet/features/device/products/litter_box/pages/litter_box_setting_page.dart';
import 'package:fullxpet/features/device/products/litter_box/pages/time_zone_search_page.dart';
import 'package:fullxpet/features/device/products/litter_box/pages/timer_mode_page.dart';
import 'package:fullxpet/features/device/products/litter_box/pages/weighing_calibration_page.dart';
import 'package:fullxpet/features/device/products/litter_box/pages/wifi_info_page.dart';
import 'package:fullxpet/features/device/products/feeder/viewmodels/feeder_viewmodel.dart';
import 'package:fullxpet/features/device/products/feeder/pages/feeder_manager_page.dart';
import 'package:fullxpet/features/device/products/feeder/pages/feeder_setting_page.dart';

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

  // Device - LitterBox 域
  static const litterBoxManager = '/device/litter_box/:id';
  static const litterBoxSetting = 'setting';
  static const litterBoxTimezone = 'timezone';
  static const litterBoxTimer = 'timer';
  static const litterBoxWifi = 'wifi';
  static const litterBoxWeighing = 'weighing';

  // Device - Feeder 域
  static const feederManager = '/device/feeder/:id';
  static const feederSetting = 'setting';

  // Device - 未登记品类拦截页
  static const deviceUnsupported = '/device/unsupported';

  // Device - Add
  static const deviceAddSearch = '/device_add_search';
  static const deviceAddWifi = 'wifi';
  static const deviceAddWifiPath = '/device_add_search/wifi';
  static const deviceAddSuccess = '/device_add_success/:id';

  /// 外部入口（设备列表、配网成功页等）统一按 productId 映射外壳路径
  static String deviceManagerPath(String id, {required String productId}) {
    switch (ProductConstants.resolveCategory(productId)) {
      case DeviceCategory.litterBox:
        return '/device/litter_box/$id';
      case DeviceCategory.feeder:
        return '/device/feeder/$id';
      case DeviceCategory.unknown:
        return deviceUnsupported;
    }
  }

  // 猫砂盆内部跳转路径
  static String litterBoxSettingPath(String id) => '/device/litter_box/$id/setting';
  static String timezonePath(String id) => '/device/litter_box/$id/setting/timezone';
  static String deviceTimerPath(String id) => '/device/litter_box/$id/setting/timer';
  static String deviceWifiPath(String id) => '/device/litter_box/$id/setting/wifi';
  static String deviceWeighingPath(String id) => '/device/litter_box/$id/setting/weighing';

  // 喂食器内部跳转路径
  static String feederSettingPath(String id) => '/device/feeder/$id/setting';

  // 配网成功路径
  static String deviceAddSuccessPath(String id, {required String productId}) =>
      Uri(path: '/device_add_success/$id', queryParameters: {'pid': productId}).toString();
  // User & Common
  static const personalInfo = '/personal_info';
  static const aboutUs = '/about_us';
  static const feedback = '/feedback';
  static const webView = '/web_view';

  // Pet
  static const petList = '/pet_list';
  static const petEdit = '/pet_edit';
}

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: NavService.rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    routes: [..._splashRoutes, ..._authRoutes, _homeShellRoute, ..._deviceRoutes, ..._userRoutes, ..._commonRoutes],
  );

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

  static final List<RouteBase> _deviceRoutes = [
    // 1. 猫砂盆独立会话外壳：管理页 -> 设置页 -> 4 个工具子页共享同一个 LitterBoxViewModel
    ShellRoute(
      builder: (context, state, child) {
        final id = state.pathParameters['id'] ?? '';
        return ChangeNotifierProvider<LitterBoxViewModel>(
          key: ValueKey('litter_box_session_$id'),
          create: (_) => LitterBoxViewModel()..initDevice(id),
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: AppRoutes.litterBoxManager,
          builder: (context, state) => LitterBoxManagerPage(deviceId: state.pathParameters['id'] ?? ''),
          routes: [
            GoRoute(
              path: AppRoutes.litterBoxSetting,
              builder: (context, state) => LitterBoxSettingPage(deviceId: state.pathParameters['id'] ?? ''),
              routes: [
                GoRoute(path: AppRoutes.litterBoxTimezone, builder: (context, state) => const TimeZoneSearchPage()),
                GoRoute(path: AppRoutes.litterBoxTimer, builder: (context, state) => const TimerModePage()),
                GoRoute(path: AppRoutes.litterBoxWifi, builder: (context, state) => const WifiInfoPage()),
                GoRoute(
                  path: AppRoutes.litterBoxWeighing,
                  builder: (context, state) => const WeighingCalibrationPage(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // 2. 喂食器独立会话外壳：管理页 -> 设置页共享同一个 FeederViewModel
    ShellRoute(
      builder: (context, state, child) {
        final id = state.pathParameters['id'] ?? '';
        return ChangeNotifierProvider<FeederViewModel>(
          key: ValueKey('feeder_session_$id'),
          create: (_) => FeederViewModel()..initDevice(id),
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: AppRoutes.feederManager,
          builder: (context, state) => FeederManagerPage(deviceId: state.pathParameters['id'] ?? ''),
          routes: [
            GoRoute(
              path: AppRoutes.feederSetting,
              builder: (context, state) => FeederSettingPage(deviceId: state.pathParameters['id'] ?? ''),
            ),
          ],
        ),
      ],
    ),

    // 3. 未登记品类显式拦截页
    GoRoute(
      path: AppRoutes.deviceUnsupported,
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('暂不支持该设备')),
        body: const Center(child: Text('当前版本暂不支持该型号设备，请升级 App 后重试')),
      ),
    ),

    // 4. 配网独立会话外壳：搜索页 -> Wi-Fi 配网页共享同一个 DeviceAddProvider
    ShellRoute(
      builder: (context, state, child) =>
          ChangeNotifierProvider<DeviceAddProvider>(create: (_) => DeviceAddProvider(), child: child),
      routes: [
        GoRoute(
          path: AppRoutes.deviceAddSearch,
          builder: (context, state) => const DeviceAddSearchPage(),
          routes: [
            GoRoute(
              path: AppRoutes.deviceAddWifi,
              builder: (context, state) {
                final device = context.read<DeviceAddProvider>().activeTargetDevice;
                if (device == null) {
                  return const _ProvisionSessionInvalidPage();
                }
                return DeviceAddWifiPage(targetDevice: device);
              },
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.deviceAddSuccess,
      builder: (context, state) {
        final deviceId = state.pathParameters['id'] ?? '';
        final productId = state.uri.queryParameters['pid'] ?? '';
        return DeviceAddSuccessPage(deviceId: deviceId, productId: productId);
      },
    ),
  ];

  static final List<GoRoute> _userRoutes = [
    GoRoute(path: AppRoutes.personalInfo, builder: (context, state) => const PersonalInfoPage()),
    GoRoute(path: AppRoutes.aboutUs, builder: (context, state) => const AboutUsPage()),
    GoRoute(path: AppRoutes.feedback, builder: (context, state) => const FeedbackPage()),
    GoRoute(path: AppRoutes.petList, builder: (context, state) => const PetListPage()),
    GoRoute(
      path: AppRoutes.petEdit,
      builder: (context, state) {
        final pet = state.extra as PetDto?;
        return PetEditPage(initialPet: pet);
      },
    ),
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

class _ProvisionSessionInvalidPage extends StatelessWidget {
  const _ProvisionSessionInvalidPage();

  void _returnToSearch(BuildContext context) {
    final router = GoRouter.of(context);
    router.go(AppRoutes.tabDevice);
    router.push(AppRoutes.deviceAddSearch);
  }

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF917CEE);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('网络配置', style: TextStyle(color: Color(0xFF333333))),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF333333)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => _returnToSearch(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: primaryPurple.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.bluetooth_disabled_rounded, size: 36, color: primaryPurple),
              ),
              const SizedBox(height: 20),
              const Text(
                '配网会话已失效',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
              ),
              const SizedBox(height: 8),
              const Text(
                '未检测到待配网的蓝牙设备，请返回重新搜索并连接设备。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.5),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: () => _returnToSearch(context),
                  child: const Text('返回重新搜索', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
