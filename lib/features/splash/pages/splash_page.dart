import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/routes/app_router.dart';
import '../viewmodels/splash_view_model.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(create: (_) => SplashViewModel(), child: const _SplashView());
  }
}

class _SplashView extends StatefulWidget {
  const _SplashView();

  @override
  State<_SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<_SplashView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAndNavigate());
  }

  Future<void> _initAndNavigate() async {
    final vm = context.read<SplashViewModel>();
    final result = await vm.bootstrapApp();

    // 业务初始化完成，移除原生闪屏，露出 Flutter 界面
    FlutterNativeSplash.remove();

    if (!mounted) return;
    switch (result) {
      case BootstrapResult.authenticated:
        context.go(AppRoutes.home);
        break;
      case BootstrapResult.unauthenticated:
      case BootstrapResult.error:
        context.go(AppRoutes.welcome);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          width: 100,
          height: 100,
          child: Image.asset('assets/images/splash_brand.png', fit: BoxFit.contain),
        ),
      ),
    );
  }
}
