import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/widgets/app_dialogs.dart';
import 'package:fullxpet/common/widgets/responsive_layout.dart';
import '../viewmodels/feeder_viewmodel.dart';

class FeederSettingPage extends StatelessWidget {
  final String deviceId;
  const FeederSettingPage({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FeederViewModel()..initDevice(deviceId),
      child: const _FeederSettingView(),
    );
  }
}

class _FeederSettingView extends StatelessWidget {
  const _FeederSettingView();

  static const Color primaryPurple = Color(0xFF917CEE);
  static const Color bgColor = Color(0xFFF9F9FC);
  static const Color textColor = Color(0xFF333333);
  static const Color offlineColor = Color(0xFFF39191);
  static const Color onlineColor = Color(0xFF8CC152);

  void _showOtaDialog(BuildContext context, FeederViewModel vm, S s) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(s.firmwareUpgrade, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Text(s.newFirmwareFound(vm.newFirmwareVersion)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancel, style: const TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await vm.startFirmwareUpgrade(timeoutSeconds: 120);
                if (success && context.mounted) {
                  context.showAppToast(message: s.upgradeDispatched, type: AppToastType.info);
                }
              },
              child: Text(
                s.confirmUpgrade,
                style: const TextStyle(color: primaryPurple, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditNameDialog(BuildContext context, FeederViewModel vm, S s) {
    final TextEditingController controller = TextEditingController(text: vm.device?.deviceName ?? '');
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
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: primaryPurple)),
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
                  final ok = await vm.updateDeviceName(newName);
                  if (ok && context.mounted) {
                    context.showAppToast(message: s.nameUpdated, type: AppToastType.success);
                  }
                }
              },
              child: Text(
                s.confirm,
                style: const TextStyle(color: primaryPurple, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showWifiDetailsSheet(BuildContext context, FeederViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
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
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '网络参数与重置',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Wi-Fi 名称', vm.wifiSsid.isNotEmpty ? vm.wifiSsid : '-'),
                _buildInfoRow('信号强度', vm.wifiRssi),
                _buildInfoRow('IP 地址', vm.wifiIp),
                _buildInfoRow('MAC 地址', vm.wifiMac),
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
                      final ok = await vm.resetWifi();
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
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
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
    final dev = vm.device;

    final devName = dev?.deviceName.isNotEmpty == true ? dev!.deviceName : 'PETLUX AI Feeder';
    final isOnline = dev?.isOnline ?? false;
    final fwVer = vm.firmwareVersion.isNotEmpty ? vm.firmwareVersion : 'v1.0.0';
    final displayId = dev?.displayId ?? '-';

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
              // 1. 设备基本信息卡片（顶部展示图与名称、固件号，与猫砂盆对称）
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9FC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.pets_rounded, size: 40, color: primaryPurple),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  devName,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _showEditNameDialog(context, vm, s),
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
              ),
              const SizedBox(height: 20),

              // 2. 固件维护与工具分组
              _buildSectionTitle(s.moreTools),
              _buildCardGroup(
                children: [
                  // 固件升级 (带红点与更新轮询)
                  _buildSettingTile(
                    Icons.system_update_alt_rounded,
                    const Color(0xFFEE7C8C),
                    vm.isOtaUpdating ? s.firmwareUpgrading : s.firmwareUpgrade,
                    showDivider: true,
                    trailingText: vm.isOtaUpdating ? s.upgrading : fwVer,
                    showRedDot: vm.hasNewFirmware && !vm.isOtaUpdating,
                    isLoading: vm.isOtaUpdating,
                    onTap: (vm.hasNewFirmware && !vm.isOtaUpdating) ? () => _showOtaDialog(context, vm, s) : null,
                  ),

                  // Wi-Fi 参数与重置
                  _buildSettingTile(
                    Icons.wifi_rounded,
                    const Color(0xFF5C7CEE),
                    s.wifiInfo,
                    showDivider: true,
                    trailingText: vm.wifiSsid.isNotEmpty ? vm.wifiSsid : null,
                    onTap: () => _showWifiDetailsSheet(context, vm),
                  ),

                  // 帮助与支持
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 12, bottom: 10),
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
                  child: CircularProgressIndicator(strokeWidth: 2, color: primaryPurple),
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
