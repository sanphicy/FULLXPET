import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/features/device/products/litter_box/v3/pages/device_manager/device_setting_page.dart';
import 'package:fullxpet/features/device/products/litter_box/viewmodels/litter_box_viewmodel.dart';

/// 猫砂盆 V4 (4.0) 专属设置页：自动裁剪等离子除臭模式与称重传感器校准入口
class V4SettingPage extends StatelessWidget {
  final String deviceId;
  const V4SettingPage({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LitterBoxViewModel()..initDevice(deviceId),
      child: LitterBoxSettingView(
        deviceId: deviceId,
        showPlasmaOption: false, // V4 不展示等离子除臭排期
        showWeighingOption: false, // V4 不展示称重传感器校准
      ),
    );
  }
}
