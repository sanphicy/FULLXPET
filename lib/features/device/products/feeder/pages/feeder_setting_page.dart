import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/widgets/app_dialogs.dart';
import 'package:fullxpet/features/device/widgets/device_setting_scaffold.dart';
import '../viewmodels/feeder_viewmodel.dart';

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
  static const Color textColor = Color(0xFF333333);
  static const Color subTextColor = Color(0xFF888888);

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
      _showTimerScheduleSheet(context, vm);
    }
  }

  /// 单次定时出粮时间段排期弹窗
  void _showTimerScheduleSheet(BuildContext context, FeederViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final range = vm.singleTimerRange;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '定时出粮时间段',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        if (range == null)
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded, color: primaryPurple, size: 26),
                            onPressed: () async {
                              await _pickAndSaveTime(context, vm, setSheetState);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (range == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 36),
                        child: Text('暂无定时计划，点击右上角图标添加', style: TextStyle(fontSize: 13, color: subTextColor)),
                      )
                    else
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryPurple.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.schedule_rounded, color: primaryPurple, size: 20),
                        ),
                        title: Text(
                          '${range.start}  至  ${range.end}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        subtitle: const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text('到达时间推出推杆，结束时自动收回', style: TextStyle(fontSize: 12, color: subTextColor)),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 22),
                              onPressed: () async {
                                await _pickAndSaveTime(context, vm, setSheetState);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                              onPressed: () async {
                                await vm.removeTimerRange();
                                setSheetState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickAndSaveTime(BuildContext context, FeederViewModel vm, StateSetter setSheetState) async {
    final startPicked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      helpText: '选择出粮开始时间',
    );
    if (startPicked == null || !context.mounted) return;

    final endPicked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 22, minute: 0),
      helpText: '选择出粮闭合时间',
    );
    if (endPicked == null) return;

    final startStr = "${startPicked.hour.toString().padLeft(2, '0')}:${startPicked.minute.toString().padLeft(2, '0')}";
    final endStr = "${endPicked.hour.toString().padLeft(2, '0')}:${endPicked.minute.toString().padLeft(2, '0')}";

    await vm.setSingleTimerRange(startStr, endStr);
    setSheetState(() {});
  }

  void _showWifiDetailsSheet(BuildContext context, FeederViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return ChangeNotifierProvider.value(
          value: vm,
          child: Consumer<FeederViewModel>(
            builder: (context, model, _) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '网络参数与重置',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Wi-Fi 名称', model.wifiSsid.isNotEmpty ? model.wifiSsid : '-'),
                      _buildInfoRow('信号强度', model.wifiRssi),
                      _buildInfoRow('网络信道', model.wifiChannel),
                      _buildInfoRow('硬件地址', model.hardwareAddress),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 18),
                          label: const Text(
                            '重置设备网络 (DP 1)',
                            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final ok = await model.resetWifi();
                            if (context.mounted) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(ok ? '已发送重置网络指令' : '重置网络指令发送失败')));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: subTextColor)),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final vm = context.watch<FeederViewModel>();

    // 直接使用全品类统一的 DeviceSettingScaffold 骨架
    return DeviceSettingScaffold(
      deviceId: deviceId,
      deviceName: vm.deviceName,
      productName: vm.productName,
      displayId: vm.displayId,
      imageUrl: vm.imageUrl,
      isOnline: vm.isOnline,
      firmwareVersion: vm.firmwareVersion.isNotEmpty ? vm.firmwareVersion : 'v1.0.0',

      // 喂食器网络信息（点击弹出 Wi-Fi 详情与 DP1 重置抽屉）
      showTimezone: false,
      showWifi: true,
      wifiSsid: vm.wifiSsid,
      onWifiTap: () => _showWifiDetailsSheet(context, vm),

      // 🔌 插槽：注入喂食器特有的「定时模式开关 + 定时出粮时间段」
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

      // OTA 升级状态与回调
      hasNewFirmware: vm.hasNewFirmware,
      newFirmwareVersion: vm.newFirmwareVersion,
      isOtaUpdating: vm.isOtaUpdating,
      onStartOtaUpgrade: () => vm.startFirmwareUpgrade(timeoutSeconds: 120),

      // 统一改名与底部红色解绑删除
      onRename: (newName) => vm.updateDeviceName(newName),
      onDelete: () => vm.deleteCurrentDevice(),
    );
  }
}
