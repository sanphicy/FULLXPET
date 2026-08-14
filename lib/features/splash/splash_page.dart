import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fullxpet/core/services/region_service.dart';
import 'package:fullxpet/core/utils/token_manager.dart';
import 'package:fullxpet/locator.dart';
import 'package:fullxpet/routes/app_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrapAndNavigate();
  }

  Future<void> _bootstrapAndNavigate() async {
    final startTime = DateTime.now();

    // 1. 判断是否已登录
    final bool loggedIn = await TokenManager.isLoggedIn();

    // 2. 执行 Bootstrap 引导（拉取/读取国家缓存、解析并初始化当前数据中心 apiBaseUrl）
    try {
      await locator<RegionService>().initBootstrap(isLoggedIn: loggedIn);
    } catch (e) {
      debugPrint("Bootstrap Error: $e");
    }

    // 3. 保证至少展示 1 秒 Logo 闪屏，防止界面跳闪
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    if (elapsed < 1000) {
      await Future.delayed(Duration(milliseconds: 1000 - elapsed));
    }

    if (!mounted) return;

    // 4. 根据登录态执行路由分发
    if (loggedIn) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 100, height: 100, child: Image.asset('assets/images/logo.png', fit: BoxFit.contain)),
            const SizedBox(height: 16),
            const Text(
              'FULLX PET',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
