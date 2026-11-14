import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/features/device/products/litter_box/viewmodels/litter_box_viewmodel.dart';
import 'package:fullxpet/features/device/products/litter_box/widgets/litter_box_widgets.dart';

/// 猫砂盆 V4 (4.0) 管理页：组装 [顶部中枢 + 4键无等离子操作坞]（不插称重看板积木）
class V4ManagerPage extends StatelessWidget {
  final String deviceId;
  const V4ManagerPage({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LitterBoxViewModel()..initDevice(deviceId),
      child: LitterBoxManageScaffold(
        deviceId: deviceId,
        modelBadge: 'V4',
        showPlasmaFeature: false, // V4 无等离子
        showEmptyAction: true,
        sensorSlots: const [], // V4 不插称重看板，界面自动收起
      ),
    );
  }
}
