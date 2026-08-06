import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:fullxpet/common/constants/dimens.dart';
import 'package:fullxpet/routes/app_router.dart';

class DeviceAddSuccessPage extends StatelessWidget {
  final String deviceId;
  const DeviceAddSuccessPage({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                  decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                  child: Icon(Icons.check, size: 50.w, color: Colors.white),
                ),
                SizedBox(height: Dimens.spacingXLarge),
                Text(
                  "设备添加成功",
                  style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
                SizedBox(height: Dimens.spacingSmall),
                Text(
                  "您的设备已成功连接至网络并绑定。",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: Dimens.fontNormal, color: theme.colorScheme.onSurfaceVariant),
                ),
                SizedBox(height: 60.h),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, Dimens.buttonLarge),
                    backgroundColor: theme.colorScheme.primary,
                  ),
                  onPressed: () {
                    // 核心修改：携带真实 deviceId 跳转至设备管理页
                    context.go('/device_manager/$deviceId');
                  },
                  child: const Text(
                    "管理设备",
                    style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: Dimens.spacingNormal),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, Dimens.buttonLarge),
                    side: BorderSide(color: theme.colorScheme.outline),
                  ),
                  onPressed: () => context.go(AppRoutes.home),
                  child: Text("返回首页", style: TextStyle(color: theme.colorScheme.onSurface)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
