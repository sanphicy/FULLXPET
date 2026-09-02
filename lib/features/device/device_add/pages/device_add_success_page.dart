import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/constants/dimens.dart';
import 'package:fullxpet/routes/app_router.dart';
import 'package:fullxpet/features/device/device_provider.dart';

class DeviceAddSuccessPage extends StatelessWidget {
  final String deviceId;
  const DeviceAddSuccessPage({super.key, required this.deviceId});

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
                    // 1. 触发刷新 API
                    context.read<DeviceProvider>().fetchDevices();
                    // 2. 跳转进入管理设备页
                    context.go(AppRoutes.deviceManagerPath(deviceId));
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
                    // 1. 触发刷新 API
                    context.read<DeviceProvider>().fetchDevices();
                    // 2. 切回首页，首页 UI 会因为 fetchDevices 内的 notifyListeners 自动重绘并展示最新设备
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
