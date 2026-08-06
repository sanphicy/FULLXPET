import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fullxpet/core/utils/token_manager.dart';
import 'package:fullxpet/routes/app_router.dart';

/// 1. 静态启动页
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkLoginAndNavigate();
  }

  Future<void> _checkLoginAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    bool loggedIn = await TokenManager.isLoggedIn();
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
            // 严格限制组件最大宽高 bounds，并使用 contain 自适应显示
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

/// 2. 登录/注册引导页
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF917CEE);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 背景纹理，同样约束最大尺寸
          Positioned(
            right: -60,
            bottom: -60,
            child: Opacity(
              opacity: 0.08,
              child: SizedBox(
                width: 360,
                height: 360,
                child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  // 主 Logo 容器限制
                  SizedBox(width: 100, height: 100, child: Image.asset('assets/images/logo.png', fit: BoxFit.contain)),
                  const SizedBox(height: 16),
                  const Text(
                    'FULLX PET',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(flex: 4),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        elevation: 0,
                      ),
                      onPressed: () => context.push(AppRoutes.login),
                      child: const Text(
                        '账号登录',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD4CCF7), width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      onPressed: () => context.push(AppRoutes.register),
                      child: const Text(
                        '去注册',
                        style: TextStyle(color: primaryPurple, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
