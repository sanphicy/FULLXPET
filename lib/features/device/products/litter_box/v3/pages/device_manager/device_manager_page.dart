import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/features/device/products/litter_box/viewmodels/litter_box_viewmodel.dart';
import 'package:fullxpet/features/device/products/litter_box/widgets/litter_box_widgets.dart';

/// 猫砂盆 V3 (3.0) 管理页：组装 [顶部中枢 + DP25/26 实时称重感知看板 + 5键含等离子操作坞]
class DeviceManagerPage extends StatelessWidget {
  final String deviceId;
  const DeviceManagerPage({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LitterBoxViewModel()..initDevice(deviceId),
      child: LitterBoxManageScaffold(
        deviceId: deviceId,
        modelBadge: 'V3',
        showPlasmaFeature: true, // V3 开启等离子净味角标与按键
        showEmptyAction: true, // 开启一键换砂按键
        sensorSlots: const [
          LitterBoxWeighingCard(), // 插入 V3 专属称重感知看板积木
        ],
      ),
    );
  }
}
