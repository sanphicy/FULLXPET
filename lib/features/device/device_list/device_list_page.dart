import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/widgets/app_avatar.dart';
import 'package:fullxpet/common/widgets/responsive_layout.dart';
import 'package:fullxpet/features/device/device_list/device_card.dart';
import 'package:fullxpet/features/device/device_provider.dart';
import 'package:fullxpet/features/device/models/device_dto.dart';
import 'package:fullxpet/common/providers/user_provider.dart';
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

  // 0: 全部, 1: V3, 2: V4
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['全部', 'PETLUX V3', 'PETLUX V4'];

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
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
                        side: const BorderSide(color: Color(0xFF999999), width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        s.iUnderstand,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF333333), fontWeight: FontWeight.w500),
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
      child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.4)),
    );
  }

  void _showRenameDialog(BuildContext context, String deviceId, String currentName, S s) {
    final TextEditingController controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(s.renameDevice, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: s.enterNewDeviceName,
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _primaryPurple)),
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
                  await context.read<DeviceProvider>().renameDevice(deviceId, newName);
                }
              },
              child: Text(
                s.confirm,
                style: TextStyle(color: _primaryPurple, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, String deviceId, String deviceName, S s) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            s.deleteDevice,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor),
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
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: _primaryPurple),
                          const SizedBox(height: 12),
                          Text(
                            s.deleting,
                            style: TextStyle(fontSize: 13, color: _textColor, decoration: TextDecoration.none),
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                final success = await context.read<DeviceProvider>().deleteDevice(deviceId);
                if (!context.mounted) return;
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.deleteSuccess)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.deleteFailed)));
                }
              },
              child: Text(
                s.delete,
                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
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
                // 1. 紧凑型一体化 Header（整合头像、用户名、在线统计与操作入口）
                Selector<UserProvider, (String, String)>(
                  selector: (_, userVm) => (userVm.user.avatarUrl, userVm.user.nickname),
                  builder: (context, userData, _) {
                    final avatarUrl = userData.$1;
                    final rawName = userData.$2.trim();
                    final userName = (rawName.isNotEmpty && rawName != 'Unknown User') ? rawName : 'User';

                    return Row(
                      children: [
                        AppAvatar(avatarUrl: avatarUrl, radius: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Hello, $userName',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF222222),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Selector<DeviceProvider, int>(
                                selector: (_, devVm) => devVm.devices.where((d) => d.isOnline).length,
                                builder: (context, onlineCount, _) {
                                  return Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF8CC152),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${s.online}: $onlineCount',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.help_outline_rounded, size: 22, color: Color(0xFF666666)),
                          onPressed: () => _showHelpDialog(context, s),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 24, color: Color(0xFF222222)),
                          onPressed: () => context.push(AppRoutes.deviceAddSearch),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),

                // 2. 全部 / V3 / V4 胶囊切换栏
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _tabs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final isSelected = _selectedTabIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTabIndex = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? _primaryPurple : Colors.white,
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(color: isSelected ? _primaryPurple : const Color(0xFFE5E5E5), width: 1),
                          ),
                          child: Text(
                            _tabs[index],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF666666),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // 3. 设备分类标题
                Text(
                  s.myDevices,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textColor),
                ),
                const SizedBox(height: 10),

                // 4. 设备卡片列表（过滤与下拉刷新）
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
                        final allDevices = data.$2;

                        final filteredDevices = allDevices.where((device) {
                          if (_selectedTabIndex == 1) return !device.isV4;
                          if (_selectedTabIndex == 2) return device.isV4;
                          return true;
                        }).toList()..sort((a, b) => (b.isOnline ? 1 : 0).compareTo(a.isOnline ? 1 : 0));

                        if (isLoading && filteredDevices.isEmpty) {
                          return ListView(
                            children: [
                              const SizedBox(height: 60),
                              Center(child: CircularProgressIndicator(color: _primaryPurple)),
                            ],
                          );
                        }

                        return ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          itemCount: filteredDevices.length,
                          itemBuilder: (context, index) {
                            final device = filteredDevices[index];
                            return DeviceCard(
                              deviceName: device.deviceName,
                              deviceId: device.displayId,
                              isOnline: device.isOnline,
                              imageUrl: device.displayImage,
                              onTap: () {
                                context.push('/device_manager/${device.deviceId}');
                              },
                              onRename: () => _showRenameDialog(context, device.deviceId, device.deviceName, s),
                              onDelete: () => _showDeleteConfirmDialog(context, device.deviceId, device.deviceName, s),
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
