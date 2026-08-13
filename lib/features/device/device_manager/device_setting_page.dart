import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fullxpet/features/device/active_device_provider.dart';
import 'package:fullxpet/common/widgets/app_wheel_picker_sheet.dart';
import 'package:fullxpet/common/widgets/app_dialogs.dart';

class DeviceSettingPage extends StatelessWidget {
  final String deviceId;
  const DeviceSettingPage({super.key, required this.deviceId});

  Future<void> _pickDndTime(BuildContext context, ActiveDeviceProvider provider) async {
    final start = await showTimePicker(context: context, initialTime: TimeOfDay.now(), helpText: '设置开始时间');
    if (start == null || !context.mounted) return;
    final end = await showTimePicker(context: context, initialTime: TimeOfDay.now(), helpText: '设置结束时间');
    if (end == null) return;
    provider.setDndTime(
      "${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}",
      "${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}",
    );
  }

  void _showOtaDialog(BuildContext context, ActiveDeviceProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('固件升级', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Text('检测到新版本 (${provider.newFirmwareVersion})，是否立即升级？升级过程约需要 1~2 分钟。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await provider.startFirmwareUpgrade(timeoutSeconds: 120);
                if (success && context.mounted) {
                  context.showAppToast(message: "升级指令已下发，正在检测升级状态...", type: AppToastType.info);
                }
              },
              child: const Text(
                '确认升级',
                style: TextStyle(color: Color(0xFF917CEE), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActiveDeviceProvider>();
    final device = provider.currentDevice;

    const Color primaryPurple = Color(0xFF917CEE);
    const Color bgColor = Color(0xFFF9F9FC);
    const Color textColor = Color(0xFF333333);
    const Color offlineColor = Color(0xFFF39191);
    const Color onlineColor = Color(0xFF8CC152);

    if (device == null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
        body: const Center(child: CircularProgressIndicator(color: primaryPurple)),
      );
    }

    final dndRange = device.dndTimeRange;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '设备设置',
          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: provider.isLoading && device.firmwareVersion.isEmpty
          ? const Center(child: CircularProgressIndicator(color: primaryPurple))
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                // ==============================
                // 1. 设备基本信息卡片
                // ==============================
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/images/product-pic.png',
                        width: 70,
                        height: 70,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.devices, size: 70, color: Colors.grey),
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
                                  device.deviceName,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                                ),
                                GestureDetector(
                                  onTap: () => _showEditNameDialog(context, provider),
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
                                    color: device.isOnline ? onlineColor : offlineColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  device.isOnline ? '在线' : '离线',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: device.isOnline ? onlineColor : offlineColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '固件版本: ${device.firmwareVersion}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '设备序列号: ${device.displayId}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 时区设置
                _buildCardGroup(
                  children: [
                    _buildSettingTile(
                      Icons.public_rounded,
                      const Color(0xFF7C8CEE),
                      '时区设置',
                      trailingText: provider.currentTimeZoneOffset,
                      onTap: () => context.push('/device_setting/$deviceId/timezone'),
                    ),
                  ],
                ),

                _buildSectionTitle('模式与参数配置'),
                _buildCardGroup(
                  children: [
                    _buildSettingTile(
                      Icons.autorenew_rounded,
                      const Color(0xFF917CEE),
                      '自动模式延时',
                      showDivider: true,
                      trailingText: '${provider.autoModeOptions[provider.autoModeIndex]} 分钟',
                      onTap: () {
                        AppWheelPickerSheet.show(
                          context,
                          title: '自动模式',
                          items: provider.autoModeOptions.map((e) => '$e 分钟').toList(),
                          initialIndex: provider.autoModeIndex,
                          onConfirm: (int index) => provider.updateAutoMode(index),
                        );
                      },
                    ),
                    _buildSettingTile(
                      Icons.nightlight_round,
                      const Color(0xFF7C8CEE),
                      '勿扰时间段',
                      showDivider: true,
                      trailingText: '${dndRange['start']} - ${dndRange['end']}',
                      onTap: () => _pickDndTime(context, provider),
                    ),
                    _buildSettingTile(
                      Icons.timer_rounded,
                      const Color(0xFF3B9EBA),
                      '定时模式计划',
                      onTap: () => context.push('/device_setting/$deviceId/timer'),
                    ),
                  ],
                ),

                _buildSectionTitle('更多工具与辅助'),
                _buildCardGroup(
                  children: [
                    _buildSettingTile(
                      Icons.system_update_alt_rounded,
                      const Color(0xFFEE7C8C),
                      provider.isOtaUpdating ? '固件升级中...' : '固件升级',
                      showDivider: true,
                      trailingText: provider.isOtaUpdating ? '升级中' : device.firmwareVersion,
                      showRedDot: provider.hasNewFirmware && !provider.isOtaUpdating,
                      isLoading: provider.isOtaUpdating,
                      onTap: (provider.hasNewFirmware && !provider.isOtaUpdating)
                          ? () => _showOtaDialog(context, provider)
                          : null,
                    ),
                    _buildSettingTile(
                      Icons.wifi_rounded,
                      const Color(0xFF5C7CEE),
                      'Wi-Fi 信息',
                      showDivider: true,
                      onTap: () => context.push('/device_setting/$deviceId/wifi'),
                    ),
                    _buildSettingTile(
                      Icons.monitor_weight_outlined,
                      const Color(0xFFEEA27C),
                      '称重校准',
                      showDivider: true,
                      onTap: () => context.push('/device_setting/$deviceId/weighing'),
                    ),
                    _buildSettingTile(
                      Icons.help_outline_rounded,
                      const Color(0xFF3B9EBA),
                      '使用帮助与支持',
                      onTap: () async {
                        final Uri url = Uri.parse('https://jooyopet.com/support');
                        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                          debugPrint('Error launching URL');
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  void _showEditNameDialog(BuildContext context, ActiveDeviceProvider provider) {
    final TextEditingController controller = TextEditingController(text: provider.currentDevice?.deviceName ?? '');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('修改设备名称', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '请输入新的设备名称',
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF917CEE))),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                FocusManager.instance.primaryFocus?.unfocus();
                final newName = controller.text.trim();
                Navigator.pop(ctx);
                if (newName.isNotEmpty) {
                  await provider.updateDeviceName(newName);
                }
              },
              child: const Text(
                '确认修改',
                style: TextStyle(color: Color(0xFF917CEE), fontWeight: FontWeight.bold),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
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
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
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
