import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/widgets/app_wheel_picker_sheet.dart';
import 'package:fullxpet/features/device/products/litter_box/viewmodels/litter_box_viewmodel.dart';
import 'package:fullxpet/features/device/widgets/device_setting_scaffold.dart';
import 'package:fullxpet/routes/app_router.dart';
import 'plasma_schedule_sheet.dart';

class LitterBoxSettingView extends StatelessWidget {
  final String deviceId;
  final bool showPlasmaOption;
  final bool showWeighingOption;

  const LitterBoxSettingView({
    super.key,
    required this.deviceId,
    required this.showPlasmaOption,
    required this.showWeighingOption,
  });

  static const Color _primaryPurple = Color(0xFF917CEE);

  Future<void> _pickDndTime(BuildContext context, LitterBoxViewModel vm) async {
    final start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 22, minute: 0),
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (start == null || !context.mounted) return;

    final end = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 6, minute: 0),
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (end == null) return;

    await vm.setDndTime(
      "${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}",
      "${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}",
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final vm = context.watch<LitterBoxViewModel>();

    return DeviceSettingScaffold(
      deviceId: deviceId,
      deviceName: vm.deviceName,
      productName: vm.productName,
      displayId: vm.displayId,
      imageUrl: vm.imageUrl,
      isOnline: vm.isOnline,
      firmwareVersion: vm.firmwareVersion,
      showTimezone: true,
      timezoneText: vm.currentTimeZoneOffset,
      onTimezoneTap: () => context.push(AppRoutes.timezonePath(deviceId), extra: vm),
      showWifi: true,
      wifiSsid: vm.wifiSsid,
      onWifiTap: () => context.push(AppRoutes.deviceWifiPath(deviceId), extra: vm),
      customSections: [
        DeviceSettingSectionTitle(title: s.modeAndParams),
        DeviceSettingCardGroup(
          children: [
            DeviceSettingTile(
              icon: Icons.autorenew_rounded,
              iconColor: _primaryPurple,
              title: s.autoModeDelay,
              trailingText: '${vm.autoModeOptions[vm.autoModeIndex]} ${s.minutesUnit}',
              showDivider: true,
              onTap: () {
                AppWheelPickerSheet.show(
                  context,
                  title: s.autoModeDelay,
                  items: vm.autoModeOptions.map((e) => '$e ${s.minutesUnit}').toList(),
                  initialIndex: vm.autoModeIndex,
                  onConfirm: (int index) => vm.updateAutoModeDelay(index),
                );
              },
            ),
            if (showPlasmaOption)
              DeviceSettingTile(
                icon: Icons.bubble_chart_rounded,
                iconColor: _primaryPurple,
                title: '等离子除臭模式',
                trailingText: vm.isPlasmaAlwaysOn ? '常开模式' : '循环模式',
                showDivider: true,
                onTap: () => PlasmaScheduleSheet.show(context, vm, s),
              ),
            DeviceSettingTile(
              icon: Icons.nightlight_round,
              iconColor: const Color(0xFF7C8CEE),
              title: s.dndTimeRange,
              trailingText: vm.dndRangeText,
              showDivider: true,
              onTap: () => _pickDndTime(context, vm),
            ),
            DeviceSettingTile(
              icon: Icons.timer_rounded,
              iconColor: const Color(0xFF3B9EBA),
              title: s.timerSchedule,
              trailingText: vm.timerList.isNotEmpty ? '已设 ${vm.timerList.length} 组' : null,
              showDivider: false,
              onTap: () => context.push(AppRoutes.deviceTimerPath(deviceId), extra: vm),
            ),
          ],
        ),
      ],
      hasNewFirmware: vm.hasNewFirmware,
      newFirmwareVersion: vm.newFirmwareVersion,
      isOtaUpdating: vm.isOtaUpdating,
      onStartOtaUpgrade: () => vm.startFirmwareUpgrade(timeoutSeconds: 120),
      extraToolTiles: [
        if (showWeighingOption)
          DeviceSettingTile(
            icon: Icons.monitor_weight_outlined,
            iconColor: const Color(0xFFEEA27C),
            title: s.weighingCalibration,
            showDivider: true,
            onTap: () => context.push(AppRoutes.deviceWeighingPath(deviceId), extra: vm),
          ),
      ],
      onRename: (newName) => vm.updateDeviceName(newName),
      onDelete: () => vm.deleteCurrentDevice(),
    );
  }
}
