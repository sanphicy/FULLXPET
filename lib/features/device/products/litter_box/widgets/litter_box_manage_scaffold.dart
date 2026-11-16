import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/widgets/responsive_layout.dart';
import 'package:fullxpet/features/device/products/litter_box/viewmodels/litter_box_viewmodel.dart';
import 'package:fullxpet/features/device/widgets/device_detail_app_bar.dart';
import 'package:fullxpet/routes/app_router.dart';
import 'litter_box_control_panel.dart';
import 'litter_box_hero_card.dart';

typedef WidgetList = List<Widget>;

class LitterBoxManageScaffold extends StatelessWidget {
  final String deviceId;
  final String modelBadge;
  final bool showPlasmaFeature;
  final bool showEmptyAction;
  final Widget? mediaSlot;
  final WidgetList sensorSlots;

  const LitterBoxManageScaffold({
    super.key,
    required this.deviceId,
    required this.modelBadge,
    this.showPlasmaFeature = false,
    this.showEmptyAction = true,
    this.mediaSlot,
    this.sensorSlots = const [],
  });

  static const Color _bgPage = Color(0xFFF9F9FC);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LitterBoxViewModel>();

    return Scaffold(
      backgroundColor: _bgPage,
      appBar: DeviceDetailAppBar(
        title: vm.deviceName,
        modelBadge: modelBadge,
        subtitle: 'ID: ${vm.displayId}',
        onSettingTap: () {
          context.push(AppRoutes.deviceSettingPath(deviceId));
        },
      ),
      body: SafeArea(
        child: ResponsiveFormContainer(
          maxWidth: 600,
          child: RefreshIndicator(
            color: const Color(0xFF917CEE),
            onRefresh: () => vm.initDevice(deviceId),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (vm.isShitBinNearlyFull) ...[_buildAlertBanner(vm.shitWeightGrams), const SizedBox(height: 14)],
                  if (mediaSlot != null) ...[mediaSlot!, const SizedBox(height: 14)],
                  LitterBoxHeroCard(showPlasmaBadge: showPlasmaFeature),
                  const SizedBox(height: 14),
                  for (final slotWidget in sensorSlots) ...[slotWidget, const SizedBox(height: 14)],
                  LitterBoxControlPanel(showPlasmaAction: showPlasmaFeature, showEmptyAction: showEmptyAction),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertBanner(int grams) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFF37474).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF37474), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '集便仓即将满仓 (${grams}g)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
                ),
                const SizedBox(height: 2),
                const Text('请及时更换垃圾袋，避免影响自动清理', style: TextStyle(fontSize: 10, color: Color(0xFFEF4444))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
