import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/constants/dimens.dart';
import 'package:fullxpet/routes/app_router.dart';
import 'package:fullxpet/features/device/device_provider.dart';

class DeviceAddSuccessPage extends StatelessWidget {
  final String deviceId;
  final String productId;

  const DeviceAddSuccessPage({super.key, required this.deviceId, required this.productId});

  static const Color _primaryPurple = Color(0xFF917CEE);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: Dimens.pagePadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100.w,
                  height: 100.w,
                  decoration: const BoxDecoration(color: _primaryPurple, shape: BoxShape.circle),
                  child: Icon(Icons.check, size: 50.w, color: Colors.white),
                ),
                SizedBox(height: Dimens.spacingXLarge),
                Text(
                  "设备添加成功",
                  style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
                ),
                SizedBox(height: Dimens.spacingSmall),
                Text(
                  "您的设备已成功连接至网络并绑定。",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: Dimens.fontNormal, color: const Color(0xFF666666)),
                ),
                SizedBox(height: 60.h),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, Dimens.buttonLarge),
                    backgroundColor: _primaryPurple,
                  ),
                  onPressed: () {
                    final router = GoRouter.of(context);
                    // 1. 触发刷新首页设备列表
                    context.read<DeviceProvider>().fetchDevices();
                    // 2. 先将底栈切回首页，再 push 进入对应品类外壳（保证管理页点返回能正常退回首页）
                    router.go(AppRoutes.tabDevice);
                    router.push(AppRoutes.deviceManagerPath(deviceId, productId: productId));
                  },
                  child: const Text(
                    "管理设备",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: Dimens.spacingNormal),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, Dimens.buttonLarge),
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  onPressed: () {
                    context.read<DeviceProvider>().fetchDevices();
                    context.go(AppRoutes.home);
                  },
                  child: const Text("返回首页", style: TextStyle(color: Color(0xFF333333))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
