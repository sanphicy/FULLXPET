import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/routes/app_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/features/device/device_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

//应用根组件
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // 注册全局设备状态
      providers: [ChangeNotifierProvider(create: (_) => DeviceProvider())],
      child: ScreenUtilInit(
        // 设计稿尺寸
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        // 限制文本最大缩放
        fontSizeResolver: (fontSize, instance) {
          final scale = instance.scaleText;
          final clampedScale = scale > 1.2 ? 1.2 : scale;
          return fontSize * clampedScale;
        },
        builder: (context, child) {
          return MaterialApp.router(
            title: 'FULLXPET',
            debugShowCheckedModeBanner: false,
            routerConfig: AppRouter.router,
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
