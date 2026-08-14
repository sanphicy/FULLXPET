import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/routes/app_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/features/device/device_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => DeviceProvider())],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp.router(
            title: 'FULLXPET',
            debugShowCheckedModeBanner: true,
            routerConfig: AppRouter.router,
            // 国际化配置：自动适配系统当前语言，支持中文/英文等全量 S.supportedLocales
            supportedLocales: S.supportedLocales,
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF917CEE)),
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.white,
            ),
          );
        },
      ),
    );
  }
}
