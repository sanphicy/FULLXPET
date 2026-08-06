import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // 1. 导入包
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/routes/app_router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'PETLUX-V3',
          routerConfig: AppRouter.router,
          supportedLocales: S.supportedLocales,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: const Locale('zh'),
          theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD3B543)), useMaterial3: true),
        );
      },
    );
  }
}
