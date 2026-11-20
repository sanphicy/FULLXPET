import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/litter_box_viewmodel.dart';
import '../widgets/litter_box_manage_scaffold.dart';
import '../widgets/litter_box_weighing_card.dart';

class LitterBoxManagerPage extends StatelessWidget {
  final String deviceId;
  const LitterBoxManagerPage({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Consumer<LitterBoxViewModel>(
      builder: (context, vm, _) {
        return LitterBoxManageScaffold(
          deviceId: deviceId,
          modelBadge: vm.modelBadge,
          showPlasmaFeature: vm.supportPlasma,
          showEmptyAction: true,
          sensorSlots: vm.supportWeighing ? const [LitterBoxWeighingCard()] : const [],
        );
      },
    );
  }
}
