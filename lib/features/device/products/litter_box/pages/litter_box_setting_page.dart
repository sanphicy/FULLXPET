import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/litter_box_viewmodel.dart';
import '../widgets/litter_box_setting_view.dart';

class LitterBoxSettingPage extends StatelessWidget {
  final String deviceId;
  const LitterBoxSettingPage({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LitterBoxViewModel()..initDevice(deviceId),
      child: Consumer<LitterBoxViewModel>(
        builder: (context, vm, _) {
          return LitterBoxSettingView(
            deviceId: deviceId,
            showPlasmaOption: vm.supportPlasma,
            showWeighingOption: vm.supportWeighing,
          );
        },
      ),
    );
  }
}
