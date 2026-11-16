import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/widgets/app_dialogs.dart';
import 'package:fullxpet/common/widgets/responsive_layout.dart';
import 'package:fullxpet/routes/app_router.dart';
import 'device_setting_tiles.dart';

export 'device_setting_tiles.dart';

typedef AsyncStringCallback = Future<bool> Function(String newName);
typedef AsyncBoolCallback = Future<bool> Function();

class DeviceSettingScaffold extends StatelessWidget {
  final String deviceId;
  final String deviceName;
  final String productName;
  final String displayId;
  final String imageUrl;
  final bool isOnline;
  final String firmwareVersion;

  // --- 中间插槽：各产品专属的配置卡片组 ---
  final SettingWidgetList customSections;

  // --- 通用硬件维护组配置与扩展插槽 ---
  final bool showTimezone;
  final String timezoneText;
  final VoidCallback? onTimezoneTap;

  final bool showWifi;
  final String wifiSsid;
  final VoidCallback? onWifiTap;

  final bool hasNewFirmware;
  final String newFirmwareVersion;
  final bool isOtaUpdating;
  final AsyncBoolCallback? onStartOtaUpgrade;

  /// 硬件维护组内的额外工具项（如 V3 插入「称重传感器校准」，V4/喂食器不插）
  final SettingWidgetList extraToolTiles;

  // --- 通用动作回调：改名 & 解绑删除 ---
  final AsyncStringCallback onRename;
  final AsyncBoolCallback onDelete;

  const DeviceSettingScaffold({
    super.key,
    required this.deviceId,
    required this.deviceName,
    this.productName = '',
    required this.displayId,
    required this.imageUrl,
    required this.isOnline,
    required this.firmwareVersion,
    this.customSections = const [],
    this.showTimezone = false,
    this.timezoneText = '',
    this.onTimezoneTap,
    this.showWifi = true,
    this.wifiSsid = '',
    this.onWifiTap,
    this.hasNewFirmware = false,
    this.newFirmwareVersion = '',
    this.isOtaUpdating = false,
    this.onStartOtaUpgrade,
    this.extraToolTiles = const [],
    required this.onRename,
    required this.onDelete,
  });

  static const int kStandardBatchIdLength = 13;
  static const int kMaxNicknameLength = 16;

  static const Color primaryPurple = Color(0xFF917CEE);
  static const Color bgColor = Color(0xFFF9F9FC);
  static const Color textColor = Color(0xFF333333);
  static const Color subTextColor = Color(0xFF888888);
  static const Color offlineColor = Color(0xFFF39191);
  static const Color onlineColor = Color(0xFF8CC152);
  static const Color dangerColor = Color(0xFFF37474);

  String get _formattedId {
    final clean = displayId.trim();
    if (clean.length <= kStandardBatchIdLength) return clean;
    return '${clean.substring(0, kStandardBatchIdLength)}…';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          s.deviceSetting,
          style: const TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w800),
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
              // 1. 【固定公共层】顶部设备身份信息主卡 (还原 HTML 原型第 1 卡)
              _buildIdentityCard(context, s),
              const SizedBox(height: 16),

              // 2. 【基础网络与时区组】（按需展示时区与 Wi-Fi）
              if (showTimezone || showWifi) ...[
                const DeviceSettingSectionTitle(title: '基础与网络配置'),
                DeviceSettingCardGroup(
                  children: [
                    if (showTimezone)
                      DeviceSettingTile(
                        icon: Icons.public_rounded,
                        iconColor: const Color(0xFF7C8CEE),
                        title: s.timezoneSetting,
                        trailingText: timezoneText,
                        showDivider: showWifi,
                        onTap: onTimezoneTap,
                      ),
                    if (showWifi)
                      DeviceSettingTile(
                        icon: Icons.wifi_rounded,
                        iconColor: const Color(0xFF5C7CEE),
                        title: s.wifiInfo,
                        trailingText: wifiSsid.isNotEmpty ? wifiSsid : null,
                        onTap: onWifiTap,
                      ),
                  ],
                ),
              ],

              // 3. 🔌【中间业务插槽】具体产品专属的参数配置组 (如猫砂盆模式参数 / 喂食器定时参数)
              ...customSections,

              // 4. 【固定公共层】硬件维护与支持组 (OTA + 扩展工具插槽 + 帮助中心)
              DeviceSettingSectionTitle(title: s.moreTools),
              DeviceSettingCardGroup(
                children: [
                  DeviceSettingTile(
                    icon: Icons.system_update_alt_rounded,
                    iconColor: const Color(0xFFEE7C8C),
                    title: isOtaUpdating ? s.firmwareUpgrading : s.firmwareUpgrade,
                    trailingText: isOtaUpdating
                        ? s.upgrading
                        : (hasNewFirmware ? '发现新版本 $newFirmwareVersion' : firmwareVersion),
                    showRedDot: hasNewFirmware && !isOtaUpdating,
                    isLoading: isOtaUpdating,
                    showDivider: true,
                    onTap: (hasNewFirmware && !isOtaUpdating && onStartOtaUpgrade != null)
                        ? () => _showOtaDialog(context, s)
                        : null,
                  ),
                  // 注入产品专属维护项（例如 V3 的「称重传感器校准」）
                  ...extraToolTiles,
                  DeviceSettingTile(
                    icon: Icons.help_outline_rounded,
                    iconColor: const Color(0xFF3B9EBA),
                    title: s.helpAndSupport,
                    showDivider: false,
                    onTap: () async {
                      final Uri url = Uri.parse('https://petlux.nl/help');
                      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                        debugPrint('Error launching URL');
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 5. 【固定公共层】底部红色「解除绑定并移除设备」按钮
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFEF2F2),
                    foregroundColor: dangerColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: dangerColor),
                  label: Text(
                    s.deleteDevice,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: dangerColor),
                  ),
                  onPressed: () => _showDeleteConfirmDialog(context, s),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// 顶部设备身份信息主卡（统一纯网络图 + 16字限制改名 + 在线状态 + 产品名 + 固件与13位序列号）
  Widget _buildIdentityCard(BuildContext context, S s) {
    final displayTitle = deviceName.trim().isNotEmpty ? deviceName.trim() : 'FULLXPET';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.025), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(18)),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.devices_other_rounded, size: 34, color: primaryPurple),
                  )
                : const Icon(Icons.devices_other_rounded, size: 34, color: primaryPurple),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        displayTitle,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showEditNameDialog(context, s, displayTitle),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.edit_outlined, color: subTextColor, size: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: isOnline ? onlineColor : offlineColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isOnline ? s.online : s.offline,
                      style: TextStyle(
                        fontSize: 12,
                        color: isOnline ? onlineColor : offlineColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (productName.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('|', style: TextStyle(fontSize: 11, color: Color(0xFFDDDDDD))),
                      ),
                      Flexible(
                        child: Text(
                          productName,
                          style: const TextStyle(fontSize: 12, color: subTextColor, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 2,
                  children: [
                    Text(
                      '${s.firmwareVersion}:${firmwareVersion.isNotEmpty ? firmwareVersion : "-"}',
                      style: const TextStyle(fontSize: 11, color: subTextColor, fontFamily: 'monospace'),
                    ),
                    Text(
                      '${s.serialNumber}:$_formattedId',
                      style: const TextStyle(fontSize: 11, color: subTextColor, fontFamily: 'monospace'),
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

  /// 统一重命名弹窗（内置 16 字符上限限制）
  void _showEditNameDialog(BuildContext context, S s, String currentName) {
    final TextEditingController controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(s.renameDevice, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: kMaxNicknameLength,
            decoration: InputDecoration(
              hintText: s.enterNewDeviceName,
              counterText: '',
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
                if (newName.isNotEmpty && newName != currentName) {
                  final ok = await onRename(newName);
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

  /// 统一 OTA 升级确认弹窗
  void _showOtaDialog(BuildContext context, S s) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(s.firmwareUpgrade, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Text(s.newFirmwareFound(newFirmwareVersion)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancel, style: const TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                if (onStartOtaUpgrade != null) {
                  final success = await onStartOtaUpgrade!();
                  if (success && context.mounted) {
                    context.showAppToast(message: s.upgradeDispatched, type: AppToastType.info);
                  }
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

  /// 统一解绑并移除设备弹窗（完成后直接返回首页列表）
  void _showDeleteConfirmDialog(BuildContext context, S s) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            s.deleteDevice,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
          ),
          content: Text(s.deleteDeviceConfirm(deviceName), style: const TextStyle(fontSize: 14, color: subTextColor)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancel, style: const TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                BuildContext? loadingCtx;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  useRootNavigator: true,
                  builder: (dialogCtx) {
                    loadingCtx = dialogCtx;
                    return const Center(child: CircularProgressIndicator(color: primaryPurple));
                  },
                );

                final success = await onDelete();

                if (loadingCtx != null && loadingCtx!.mounted) {
                  Navigator.of(loadingCtx!).pop();
                }
                if (!context.mounted) return;

                if (success) {
                  context.showAppToast(message: s.deleteSuccess, type: AppToastType.success);
                  context.go(AppRoutes.home);
                } else {
                  context.showAppToast(message: s.deleteFailed, type: AppToastType.error);
                }
              },
              child: Text(
                s.delete,
                style: const TextStyle(color: dangerColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
