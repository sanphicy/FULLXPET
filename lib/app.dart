import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:fullxpet/common/config/app_config.dart'; // 1. 导入配置类[cite: 2]
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/theme/app_theme.dart';
import 'package:fullxpet/features/device/device_provider.dart';
import 'package:fullxpet/features/user/providers/user_provider.dart';
import 'package:fullxpet/locator.dart';
import 'package:fullxpet/routes/app_router.dart';
import 'package:fullxpet/common/constants/dimens.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // 统一本地化代理列表
  static const List<LocalizationsDelegate<dynamic>> _localizationsDelegates = [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
  static double _resolveFontSize(num fontSize, ScreenUtil instance) {
    final scale = instance.scaleText;
    return fontSize * (scale > 1.2 ? 1.2 : scale);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: locator<UserProvider>()),
        ChangeNotifierProvider.value(value: locator<DeviceProvider>()),
      ],
      child: ScreenUtilInit(
        designSize: Dimens.designSize,
        minTextAdapt: true,
        splitScreenMode: true,
        fontSizeResolver: _resolveFontSize,
        builder: (context, child) {
          return MaterialApp.router(
            title: locator<AppConfig>().appName,
            debugShowCheckedModeBanner: false,
            routerConfig: AppRouter.router,
            supportedLocales: S.supportedLocales,
            localizationsDelegates: _localizationsDelegates,
            theme: AppTheme.lightTheme,
          );
        },
      ),
    );
  }
}
