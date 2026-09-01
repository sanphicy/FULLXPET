import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/widgets/app_dialogs.dart';
import 'package:fullxpet/common/widgets/app_wheel_picker_sheet.dart';
import 'package:fullxpet/common/widgets/responsive_layout.dart';
import 'package:fullxpet/features/device/active_device_provider.dart';

class DeviceSettingPage extends StatelessWidget {
  final String deviceId;
  const DeviceSettingPage({super.key, required this.deviceId});

  Future<void> _pickDndTime(BuildContext context, ActiveDeviceProvider provider) async {
    final start = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (start == null || !context.mounted) return;

    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (end == null) return;

    provider.setDndTime(
      "${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}",
      "${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}",
    );
  }

  void _showOtaDialog(BuildContext context, ActiveDeviceProvider provider, S s) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(s.firmwareUpgrade, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Text(s.newFirmwareFound(provider.newFirmwareVersion)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancel, style: const TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await provider.startFirmwareUpgrade(timeoutSeconds: 120);
                if (success && context.mounted) {
                  context.showAppToast(message: s.upgradeDispatched, type: AppToastType.info);
                }
              },
              child: Text(
                s.confirmUpgrade,
                style: const TextStyle(color: Color(0xFF917CEE), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final provider = context.read<ActiveDeviceProvider>();

    const Color primaryPurple = Color(0xFF917CEE);
    const Color bgColor = Color(0xFFF9F9FC);
    const Color textColor = Color(0xFF333333);
    const Color offlineColor = Color(0xFFF39191);
    const Color onlineColor = Color(0xFF8CC152);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          s.deviceSetting,
          style: const TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ResponsiveFormContainer(
          maxWidth: 600,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: [
              // 1. 设备基本信息卡片（局部监听）
              Selector<ActiveDeviceProvider, (String, bool, String, String)>(
                selector: (_, vm) => (
                  vm.currentDevice?.deviceName ?? '',
                  vm.currentDevice?.isOnline ?? false,
                  vm.currentDevice?.firmwareVersion ?? '',
                  vm.currentDevice?.displayId ?? '',
                ),
                builder: (context, dev, _) {
                  final devName = dev.$1.isNotEmpty ? dev.$1 : 'FULLXPET';
                  final isOnline = dev.$2;
                  final fwVer = dev.$3;
                  final displayId = dev.$4;

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          'assets/images/product-pic.png',
                          width: 70,
                          height: 70,
                          errorBuilder: (_, __, ___) => const Icon(Icons.devices, size: 70, color: Colors.grey),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    devName,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showEditNameDialog(context, provider, s),
                                    child: Icon(Icons.edit_outlined, color: Colors.grey.shade400, size: 18),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: isOnline ? onlineColor : offlineColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isOnline ? s.online : s.offline,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isOnline ? onlineColor : offlineColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${s.firmwareVersion}: $fwVer',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${s.serialNumber}: $displayId',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // 2. 时区设置
              _buildCardGroup(
                children: [
                  Selector<ActiveDeviceProvider, String>(
                    selector: (_, vm) => vm.currentTimeZoneOffset,
                    builder: (context, tzOffset, _) {
                      return _buildSettingTile(
                        Icons.public_rounded,
                        const Color(0xFF7C8CEE),
                        s.timezoneSetting,
                        trailingText: tzOffset,
                        onTap: () => context.push('/device_setting/$deviceId/timezone'),
                      );
                    },
                  ),
                ],
              ),

              // 3. 模式与参数配置
              _buildSectionTitle(s.modeAndParams),
              _buildCardGroup(
                children: [
                  Selector<ActiveDeviceProvider, int>(
                    selector: (_, vm) => vm.autoModeIndex,
                    builder: (context, autoIdx, _) {
                      return _buildSettingTile(
                        Icons.autorenew_rounded,
                        primaryPurple,
                        s.autoModeDelay,
                        showDivider: true,
                        trailingText: '${provider.autoModeOptions[autoIdx]} ${s.minutesUnit}',
                        onTap: () {
                          AppWheelPickerSheet.show(
                            context,
                            title: s.autoModeDelay,
                            items: provider.autoModeOptions.map((e) => '$e ${s.minutesUnit}').toList(),
                            initialIndex: autoIdx,
                            onConfirm: (int index) => provider.updateAutoMode(index),
                          );
                        },
                      );
                    },
                  ),
                  Selector<ActiveDeviceProvider, bool>(
                    selector: (_, vm) => vm.isPlasmaAlwaysOn,
                    builder: (context, isAlways, _) {
                      return _buildSettingTile(
                        Icons.bubble_chart_rounded,
                        const Color(0xFF917CEE),
                        '等离子除臭模式',
                        showDivider: true,
                        trailingText: isAlways ? '常开模式' : '循环模式',
                        onTap: () => _showPlasmaScheduleSheet(context, provider, s),
                      );
                    },
                  ),
                  Selector<ActiveDeviceProvider, Map<String, String>>(
                    selector: (_, vm) => vm.currentDevice?.dndTimeRange ?? {'start': '22:00', 'end': '06:00'},
                    builder: (context, dndRange, _) {
                      return _buildSettingTile(
                        Icons.nightlight_round,
                        const Color(0xFF7C8CEE),
                        s.dndTimeRange,
                        showDivider: true,
                        trailingText: '${dndRange['start']} - ${dndRange['end']}',
                        onTap: () => _pickDndTime(context, provider),
                      );
                    },
                  ),
                  _buildSettingTile(
                    Icons.timer_rounded,
                    const Color(0xFF3B9EBA),
                    s.timerSchedule,
                    onTap: () => context.push('/device_setting/$deviceId/timer'),
                  ),
                ],
              ),

              // 4. 更多工具与辅助
              _buildSectionTitle(s.moreTools),
              _buildCardGroup(
                children: [
                  // OTA 升级项独立监听
                  Selector<ActiveDeviceProvider, (bool, bool, String)>(
                    selector: (_, vm) => (vm.isOtaUpdating, vm.hasNewFirmware, vm.currentDevice?.firmwareVersion ?? ''),
                    builder: (context, otaState, _) {
                      final isUpdating = otaState.$1;
                      final hasNew = otaState.$2;
                      final currentVer = otaState.$3;

                      return _buildSettingTile(
                        Icons.system_update_alt_rounded,
                        const Color(0xFFEE7C8C),
                        isUpdating ? s.firmwareUpgrading : s.firmwareUpgrade,
                        showDivider: true,
                        trailingText: isUpdating ? s.upgrading : currentVer,
                        showRedDot: hasNew && !isUpdating,
                        isLoading: isUpdating,
                        onTap: (hasNew && !isUpdating) ? () => _showOtaDialog(context, provider, s) : null,
                      );
                    },
                  ),
                  _buildSettingTile(
                    Icons.wifi_rounded,
                    const Color(0xFF5C7CEE),
                    s.wifiInfo,
                    showDivider: true,
                    onTap: () => context.push('/device_setting/$deviceId/wifi'),
                  ),
                  _buildSettingTile(
                    Icons.monitor_weight_outlined,
                    const Color(0xFFEEA27C),
                    s.weighingCalibration,
                    showDivider: true,
                    onTap: () => context.push('/device_setting/$deviceId/weighing'),
                  ),
                  _buildSettingTile(
                    Icons.help_outline_rounded,
                    const Color(0xFF3B9EBA),
                    s.helpAndSupport,
                    onTap: () async {
                      final Uri url = Uri.parse('https://petlux.nl/help');
                      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                        debugPrint('Error launching URL');
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, ActiveDeviceProvider provider, S s) {
    final TextEditingController controller = TextEditingController(text: provider.currentDevice?.deviceName ?? '');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(s.renameDevice, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: s.enterNewDeviceName,
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF917CEE))),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancel, style: const TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                FocusManager.instance.primaryFocus?.unfocus();
                final newName = controller.text.trim();
                Navigator.pop(ctx);
                if (newName.isNotEmpty) {
                  final ok = await provider.updateDeviceName(newName);
                  if (ok && context.mounted) {
                    context.showAppToast(message: s.nameUpdated, type: AppToastType.success);
                  }
                }
              },
              child: Text(
                s.confirm,
                style: const TextStyle(color: Color(0xFF917CEE), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 22, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, color: Color(0xFF888888), fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildCardGroup({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile(
    IconData icon,
    Color iconColor,
    String title, {
    bool showDivider = false,
    String? trailingText,
    bool showRedDot = false,
    bool isLoading = false,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 14, color: Color(0xFF333333), fontWeight: FontWeight.w500),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailingText != null)
                Text(trailingText, style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
              if (isLoading) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF917CEE)),
                ),
              ] else if (showRedDot) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                ),
              ],
              const SizedBox(width: 5),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
            ],
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          onTap: isLoading ? null : onTap,
        ),
        if (showDivider) const Divider(height: 1, thickness: 0.5, indent: 52, endIndent: 16, color: Color(0xFFF0EFF5)),
      ],
    );
  }
}

void _showPlasmaScheduleSheet(BuildContext context, ActiveDeviceProvider provider, S s) {
  final currentSched = provider.plasmaSchedule;
  bool isAlwaysOn = provider.isPlasmaAlwaysOn;
  bool isFineGrained = false;

  // 换算初始分秒
  int initialRunTotal = isAlwaysOn ? 3600 : (currentSched['runTime'] ?? 3600);
  int initialOutTotal = isAlwaysOn ? 1800 : (currentSched['outTime'] ?? 1800);

  int runMinutes = initialRunTotal ~/ 60;
  int runSeconds = initialRunTotal % 60;
  int outMinutes = initialOutTotal ~/ 60;
  int outSeconds = initialOutTotal % 60;

  // 若当前含有秒数或小于1分钟，默认展开精细化
  if (runSeconds > 0 ||
      outSeconds > 0 ||
      (runMinutes == 0 && initialRunTotal > 0) ||
      (outMinutes == 0 && initialOutTotal > 0)) {
    isFineGrained = true;
  }
  if (runSeconds == 0) runSeconds = 30; // 精细化默认初值为 30s
  if (outSeconds == 0) outSeconds = 30;

  // 1. 普通模式：1 分钟起步 (1 ~ 120 / 1 ~ 360)
  final normalRunMinList = List.generate(120, (i) => i + 1);
  final normalOutMinList = List.generate(360, (i) => i + 1);

  // 2. 精细模式：0 分钟起步 (0 ~ 120 / 0 ~ 360)，秒数固定 1 ~ 59 秒 (无 0 秒)
  final fineRunMinList = List.generate(121, (i) => i);
  final fineOutMinList = List.generate(361, (i) => i);
  final secList = List.generate(59, (i) => i + 1); // 1 ~ 59 秒

  late FixedExtentScrollController runMinCtrl;
  late FixedExtentScrollController runSecCtrl;
  late FixedExtentScrollController outMinCtrl;
  late FixedExtentScrollController outSecCtrl;

  void initControllers(bool fine) {
    if (fine) {
      runMinCtrl = FixedExtentScrollController(initialItem: runMinutes.clamp(0, 120));
      outMinCtrl = FixedExtentScrollController(initialItem: outMinutes.clamp(0, 360));
    } else {
      runMinCtrl = FixedExtentScrollController(initialItem: (runMinutes - 1).clamp(0, 119));
      outMinCtrl = FixedExtentScrollController(initialItem: (outMinutes - 1).clamp(0, 359));
    }
    runSecCtrl = FixedExtentScrollController(initialItem: (runSeconds - 1).clamp(0, 58));
    outSecCtrl = FixedExtentScrollController(initialItem: (outSeconds - 1).clamp(0, 58));
  }

  initControllers(isFineGrained);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final currentRunMinList = isFineGrained ? fineRunMinList : normalRunMinList;
          final currentOutMinList = isFineGrained ? fineOutMinList : normalOutMinList;

          // 计算当前总秒数
          final currentRunTotalSec = isFineGrained ? (runMinutes * 60 + runSeconds) : (runMinutes * 60);
          final currentOutTotalSec = isFineGrained ? (outMinutes * 60 + outSeconds) : (outMinutes * 60);
          // 低于 30 秒触发硬件寿命警告
          final bool isTooShort = !isAlwaysOn && (currentRunTotalSec < 30 || currentOutTotalSec < 30);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 顶部拖动条与标题栏
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(s.cancel, style: const TextStyle(color: Colors.grey, fontSize: 15)),
                      ),
                      const Text(
                        '等离子工作模式',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          if (isAlwaysOn) {
                            provider.setPlasmaSchedule(runSeconds: 0, outSeconds: 0);
                          } else {
                            provider.setPlasmaSchedule(runSeconds: currentRunTotalSec, outSeconds: currentOutTotalSec);
                          }
                        },
                        child: const Text(
                          '确定',
                          style: TextStyle(color: Color(0xFF917CEE), fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 模式选择卡片
                  Container(
                    decoration: BoxDecoration(color: const Color(0xFFF9F9FC), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        RadioListTile<bool>(
                          value: true,
                          groupValue: isAlwaysOn,
                          activeColor: const Color(0xFF917CEE),
                          title: const Text('常开模式', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          subtitle: const Text('开启后持续工作，直到手动关闭', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          onChanged: (val) => setSheetState(() => isAlwaysOn = true),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEFEFEF)),
                        RadioListTile<bool>(
                          value: false,
                          groupValue: isAlwaysOn,
                          activeColor: const Color(0xFF917CEE),
                          title: const Text('循环模式', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          subtitle: const Text('运行指定时间后自动休眠，循环往复', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          onChanged: (val) => setSheetState(() => isAlwaysOn = false),
                        ),
                      ],
                    ),
                  ),

                  if (!isAlwaysOn) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '精细调节 (精确到秒)',
                          style: TextStyle(fontSize: 13, color: Color(0xFF666666), fontWeight: FontWeight.w500),
                        ),
                        Switch(
                          value: isFineGrained,
                          activeColor: const Color(0xFF917CEE),
                          onChanged: (val) {
                            setSheetState(() {
                              isFineGrained = val;
                              if (!isFineGrained) {
                                if (runMinutes == 0) runMinutes = 1;
                                if (outMinutes == 0) outMinutes = 1;
                              }
                              initControllers(isFineGrained);
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 运行与停歇滚轮组
                    Row(
                      children: [
                        Expanded(
                          child: _buildTimePickerColumn(
                            title: '运行工作',
                            minuteCtrl: runMinCtrl,
                            secondCtrl: runSecCtrl,
                            minList: currentRunMinList,
                            secList: secList,
                            showSeconds: isFineGrained,
                            onMinChanged: (idx) => setSheetState(() => runMinutes = currentRunMinList[idx]),
                            onSecChanged: (idx) => setSheetState(() => runSeconds = secList[idx]),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTimePickerColumn(
                            title: '停歇休眠',
                            minuteCtrl: outMinCtrl,
                            secondCtrl: outSecCtrl,
                            minList: currentOutMinList,
                            secList: secList,
                            showSeconds: isFineGrained,
                            onMinChanged: (idx) => setSheetState(() => outMinutes = currentOutMinList[idx]),
                            onSecChanged: (idx) => setSheetState(() => outSeconds = secList[idx]),
                          ),
                        ),
                      ],
                    ),

                    // 硬件寿命过频警告
                    if (isTooShort) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF9DB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFE066)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFE67700)),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '单次启闭低于30秒可能会加速除臭模块损耗',
                                style: TextStyle(fontSize: 11, color: Color(0xFFD9480F), fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildTimePickerColumn({
  required String title,
  required FixedExtentScrollController minuteCtrl,
  required FixedExtentScrollController secondCtrl,
  required List<int> minList,
  required List<int> secList,
  required bool showSeconds,
  required ValueChanged<int> onMinChanged,
  required ValueChanged<int> onSecChanged,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFF9F9FC),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFEEEEEE)),
    ),
    child: Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF555555)),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 👈 选中指示背景横条
              Container(
                height: 34,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF917CEE).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF917CEE).withValues(alpha: 0.25), width: 1),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      controller: minuteCtrl,
                      itemExtent: 34,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: onMinChanged,
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: minList.length,
                        builder: (context, index) => Center(
                          child: Text(
                            '${minList[index]} 分',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (showSeconds)
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        controller: secondCtrl,
                        itemExtent: 34,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: onSecChanged,
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: secList.length,
                          builder: (context, index) => Center(
                            child: Text(
                              '${secList[index]} 秒',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF917CEE),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
