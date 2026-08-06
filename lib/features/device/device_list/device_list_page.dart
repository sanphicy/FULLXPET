import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/widgets/app_avatar.dart';
import 'package:fullxpet/features/device/device_list/device_card.dart';
import 'package:fullxpet/features/device/device_provider.dart';
import 'package:fullxpet/features/user/user_provider.dart';
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
    });
  }

  /// 帮助弹窗
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
          backgroundColor: const Color(0xFFF4F5F0),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    '使用指南',
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
                SizedBox(height: 20.h),
                _buildGuideItem('1. 确保设备已开启并连接网络'),
                _buildGuideItem('2. 点击右上角 + 按钮添加新设备'),
                _buildGuideItem('3. 向左滑动设备卡片可重命名或删除'),
                _buildGuideItem('4. 下拉页面可手动刷新设备状态'),
                SizedBox(height: 30.h),
                Center(
                  child: SizedBox(
                    width: 140.w,
                    height: 44.h,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: const Color(0xFF999999), width: 1.w),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        '我知道了',
                        style: TextStyle(fontSize: 16.sp, color: const Color(0xFF333333), fontWeight: FontWeight.w500),
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
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: TextStyle(fontSize: 14.sp, color: const Color(0xFF666666), height: 1.5),
      ),
    );
  }

  /// 修改名称弹窗
  void _showRenameDialog(BuildContext context, String deviceId, String currentName) {
    final TextEditingController controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
          title: Text(
            '修改设备名称',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '请输入新的名称',
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _primaryPurple)),
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
                if (newName.isNotEmpty && newName != currentName) {
                  await context.read<DeviceProvider>().renameDevice(deviceId, newName);
                }
              },
              child: Text(
                '确认',
                style: TextStyle(color: _primaryPurple, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeviceProvider>();
    final userProvider = context.watch<UserProvider>();
    final onlineCount = provider.devices.where((d) => d.isOnline).length;

    return Scaffold(
      backgroundColor: _bgLight,
      body: SafeArea(
        child: RefreshIndicator(
          color: _primaryPurple,
          backgroundColor: Colors.white,
          onRefresh: () async {
            await context.read<DeviceProvider>().fetchDevices();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header (Logo + Title + Help Icon)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 36.w,
                          height: 36.w,
                          child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'FULLX PET',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.help_outline_rounded, size: 26.w, color: Colors.black87),
                      onPressed: () => _showHelpDialog(context),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // 2. Hello 问候语
                Text(
                  'Hello,',
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: _primaryPurple),
                ),
                SizedBox(height: 16.h),

                // 3. 用户与在线状态卡片
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: SizedBox(
                        width: 150.w,
                        height: 150.w,
                        child: Image.asset(
                          'assets/images/product-logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10.h,
                      left: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        decoration: const ShapeDecoration(color: Color(0xFFFCE21B), shape: StadiumBorder()),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppAvatar(avatarUrl: userProvider.avatarUrl, radius: 18.r),
                            SizedBox(width: 10.w),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  userProvider.userName.isNotEmpty ? userProvider.userName : 'CHEN',
                                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  '在线: $onlineCount',
                                  style: TextStyle(fontSize: 11.sp, color: Colors.pink, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            SizedBox(width: 12.w),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                // 4. 设备列表标题 + 添加设备按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '我的设备',
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: _textColor),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_rounded, size: 28.w, color: const Color(0xFF555555)),
                      onPressed: () => context.push(AppRoutes.deviceAddSearch),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // 5. 设备列表
                if (provider.isLoading && provider.devices.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.h),
                      child: CircularProgressIndicator(color: _primaryPurple),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.devices.length,
                    itemBuilder: (context, index) {
                      final device = provider.devices[index];
                      return DeviceCard(
                        deviceName: device.deviceName,
                        deviceId: device.deviceId,
                        isOnline: device.isOnline,
                        imageUrl: 'assets/images/product-pic.png',
                        onTap: () {
                          context.push('/device_manager/${device.deviceId}');
                        },
                        onRename: () => _showRenameDialog(context, device.deviceId, device.deviceName),
                        onDelete: () async {
                          await context.read<DeviceProvider>().deleteDevice(device.deviceId);
                          if (mounted) {
                            context.read<DeviceProvider>().fetchDevices();
                          }
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
