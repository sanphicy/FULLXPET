import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/widgets/app_dialogs.dart';
import 'package:fullxpet/features/device/widgets/device_setting_scaffold.dart';
import '../viewmodels/feeder_viewmodel.dart';
import '../widgets/feeder_timer_sheet.dart';
import '../widgets/feeder_wifi_sheet.dart';

class FeederSettingPage extends StatelessWidget {
  final String deviceId;
  const FeederSettingPage({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FeederViewModel()..initDevice(deviceId),
      child: _FeederSettingView(deviceId: deviceId),
    );
  }
}

class _FeederSettingView extends StatelessWidget {
  final String deviceId;
  const _FeederSettingView({required this.deviceId});

  static const Color primaryPurple = Color(0xFF917CEE);

  /// 弹窗提示用户：定时仅在敞开模式下生效，同意后同时下发定时=true、敞开=true
  Future<void> _handleTimerModeTap(
    BuildContext context,
    FeederViewModel vm, {
    bool openScheduleAfterAgree = true,
  }) async {
    if (!vm.isTimerEnabled) {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('定时模式提示', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            content: const Text(
              '定时仅在敞开模式下生效，开启定时将同时为您开启敞开模式，是否继续？',
              style: TextStyle(fontSize: 14, color: Color(0xFF555555), height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  '同意并开启',
                  style: TextStyle(color: primaryPurple, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );

      if (confirmed != true || !context.mounted) return;

      final ok = await vm.enableTimerWithOpenMode();
      if (!context.mounted) return;
      if (!ok) {
        context.showAppToast(message: '开启定时模式失败', type: AppToastType.error);
        return;
      }
      context.showAppToast(message: '已开启定时与敞开模式', type: AppToastType.success);
    }

    if (openScheduleAfterAgree && context.mounted) {
      FeederTimerSheet.show(context, vm);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final vm = context.watch<FeederViewModel>();

    return DeviceSettingScaffold(
      deviceId: deviceId,
      deviceName: vm.deviceName,
      productName: vm.productName,
      displayId: vm.displayId,
      imageUrl: vm.imageUrl,
      isOnline: vm.isOnline,
      firmwareVersion: vm.firmwareVersion.isNotEmpty ? vm.firmwareVersion : 'v1.0.0',
      showTimezone: false,
      showWifi: true,
      wifiSsid: vm.wifiSsid,
      onWifiTap: () => FeederWifiSheet.show(context, vm),
      customSections: [
        DeviceSettingSectionTitle(title: s.modeAndParams),
        DeviceSettingCardGroup(
          children: [
            DeviceSettingTile(
              icon: Icons.schedule_rounded,
              iconColor: primaryPurple,
              title: '定时模式',
              subtitle: vm.isTimerEnabled ? '已开启 · 点击配置时间段' : '仅在敞开模式下生效',
              showDivider: true,
              trailingWidget: Switch(
                value: vm.isTimerEnabled,
                activeThumbColor: primaryPurple,
                onChanged: (val) async {
                  if (val) {
                    await _handleTimerModeTap(context, vm, openScheduleAfterAgree: false);
                  } else {
                    await vm.disableTimerMode();
                  }
                },
              ),
              onTap: () => _handleTimerModeTap(context, vm, openScheduleAfterAgree: true),
            ),
            DeviceSettingTile(
              icon: Icons.timer_outlined,
              iconColor: const Color(0xFF3B9EBA),
              title: '定时出粮时间段',
              trailingText: vm.singleTimerRange != null
                  ? '${vm.singleTimerRange!.start}-${vm.singleTimerRange!.end}'
                  : '未设置',
              showDivider: false,
              onTap: () => _handleTimerModeTap(context, vm, openScheduleAfterAgree: true),
            ),
          ],
        ),
      ],
      hasNewFirmware: vm.hasNewFirmware,
      newFirmwareVersion: vm.newFirmwareVersion,
      isOtaUpdating: vm.isOtaUpdating,
      onStartOtaUpgrade: () => vm.startFirmwareUpgrade(timeoutSeconds: 120),
      onRename: (newName) => vm.updateDeviceName(newName),
      onDelete: () => vm.deleteCurrentDevice(),
    );
  }
}
