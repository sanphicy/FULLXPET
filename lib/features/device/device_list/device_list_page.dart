import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/widgets/app_avatar.dart';
import 'package:fullxpet/common/widgets/responsive_layout.dart';
import 'package:fullxpet/features/device/device_list/device_card.dart';
import 'package:fullxpet/features/device/device_provider.dart';
import 'package:fullxpet/features/device/models/device_dto.dart';
import 'package:fullxpet/features/user/viewmodels/user_view_model.dart';
import 'package:fullxpet/routes/app_router.dart';

class DeviceListPage extends StatefulWidget {
  const DeviceListPage({super.key});

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  final Color _primaryPurple = const Color(0xFF917CEE);
  final Color _bgLight = const Color(0xFFF9F9FC);
  final Color _textColor = const Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceProvider>().fetchDevices();
      context.read<UserProvider>().fetchUserInfo(isSilent: true);
    });
  }

  void _showHelpDialog(BuildContext context, S s) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: const Color(0xFFF4F5F0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    s.useGuide,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildGuideItem(s.guideStep1),
                _buildGuideItem(s.guideStep2),
                _buildGuideItem(s.guideStep3),
                _buildGuideItem(s.guideStep4),
                const SizedBox(height: 24),
                Center(
                  child: SizedBox(
                    width: 140,
                    height: 40,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF999999),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        s.iUnderstand,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF333333),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuideItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF666666),
          height: 1.4,
        ),
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    String deviceId,
    String currentName,
    S s,
  ) {
    final TextEditingController controller = TextEditingController(
      text: currentName,
    );
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            s.renameDevice,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: s.enterNewDeviceName,
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: _primaryPurple),
              ),
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
                  await context.read<DeviceProvider>().renameDevice(
                    deviceId,
                    newName,
                  );
                }
              },
              child: Text(
                s.confirm,
                style: TextStyle(
                  color: _primaryPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    String deviceId,
    String deviceName,
    S s,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            s.deleteDevice,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
          content: Text(
            s.deleteDeviceConfirm(deviceName),
            style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancel, style: const TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: _primaryPurple),
                          const SizedBox(height: 12),
                          Text(
                            s.deleting,
                            style: TextStyle(
                              fontSize: 13,
                              color: _textColor,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                // _showDeleteConfirmDialog 异步弹出与关闭
                final success = await context
                    .read<DeviceProvider>()
                    .deleteDevice(deviceId);
                if (!context.mounted) return;
                Navigator.pop(context); // 关闭 loading 弹窗
                if (success) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(s.deleteSuccess)));
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(s.deleteFailed)));
                }
              },
              child: Text(
                s.delete,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
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
    final deviceProvider = context.read<DeviceProvider>();

    return Scaffold(
      backgroundColor: _bgLight,
      body: SafeArea(
        child: ResponsiveFormContainer(
          maxWidth: 600,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 顶部栏 (Logo + Title + Help Icon)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'FULLX PET',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.help_outline_rounded,
                        size: 24,
                        color: Color(0xFF555555),
                      ),
                      onPressed: () => _showHelpDialog(context, s),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 2. 用户问候语（局部监听 UserProvider）
                Selector<UserProvider, String>(
                  selector: (_, userVm) => userVm.userName,
                  builder: (context, userName, _) {
                    final displayName =
                        (userName.isNotEmpty && userName != 'Unknown User')
                        ? userName
                        : '';
                    return Text(
                      displayName.isNotEmpty ? 'Hello, $displayName' : 'Hello,',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _primaryPurple,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 3. 用户头像与在线统计卡片 Banner
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: SizedBox(
                        width: 140,
                        height: 140,
                        child: Image.asset(
                          'assets/images/product-logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: const ShapeDecoration(
                          color: Color(0xFFFCE21B),
                          shape: StadiumBorder(),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Selector<UserProvider, String>(
                              selector: (_, userVm) => userVm.avatarUrl,
                              builder: (context, avatarUrl, _) =>
                                  AppAvatar(avatarUrl: avatarUrl, radius: 16),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Selector<UserProvider, String>(
                                  selector: (_, userVm) => userVm.userName,
                                  builder: (context, userName, _) {
                                    return ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 100,
                                      ),
                                      child: Text(
                                        userName.isNotEmpty ? userName : 'CHEN',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF222222),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 1),
                                Selector<DeviceProvider, int>(
                                  selector: (_, devVm) => devVm.devices
                                      .where((d) => d.isOnline)
                                      .length,
                                  builder: (context, onlineCount, _) {
                                    return Text(
                                      '${s.online}: $onlineCount',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF7A60E6),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 4. 设备列表标题 + 添加设备按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.myDevices,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_rounded,
                        size: 26,
                        color: Color(0xFF555555),
                      ),
                      onPressed: () => context.push(AppRoutes.deviceAddSearch),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 5. 设备列表刷新区（局部监听 DeviceProvider 的设备列表）
                Expanded(
                  child: RefreshIndicator(
                    color: _primaryPurple,
                    backgroundColor: Colors.white,
                    onRefresh: () async {
                      await deviceProvider.fetchDevices();
                    },
                    child: Selector<DeviceProvider, (bool, List<DeviceDto>)>(
                      selector: (_, devVm) => (devVm.isLoading, devVm.devices),
                      builder: (context, data, _) {
                        final isLoading = data.$1;
                        final devices = data.$2;

                        if (isLoading && devices.isEmpty) {
                          return ListView(
                            children: [
                              const SizedBox(height: 60),
                              Center(
                                child: CircularProgressIndicator(
                                  color: _primaryPurple,
                                ),
                              ),
                            ],
                          );
                        }

                        return ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          itemCount: devices.length,
                          itemBuilder: (context, index) {
                            final device = devices[index];
                            return DeviceCard(
                              deviceName: device.deviceName,
                              deviceId: device.displayId,
                              isOnline: device.isOnline,
                              imageUrl: 'assets/images/product-pic.png',
                              onTap: () {
                                context.push(
                                  '/device_manager/${device.deviceId}',
                                );
                              },
                              onRename: () => _showRenameDialog(
                                context,
                                device.deviceId,
                                device.deviceName,
                                s,
                              ),
                              onDelete: () => _showDeleteConfirmDialog(
                                context,
                                device.deviceId,
                                device.deviceName,
                                s,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
