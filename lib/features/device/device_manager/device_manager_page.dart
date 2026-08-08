import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fullxpet/features/device/active_device_provider.dart';
import 'package:fullxpet/features/device/models/device_thing_model.dart';

class DeviceManagerPage extends StatelessWidget {
  final String deviceId;
  const DeviceManagerPage({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActiveDeviceProvider>();
    final device = provider.currentDevice;

    const Color primaryPurple = Color(0xFF917CEE);
    const Color bgColor = Color(0xFFF9F9FC);
    const Color textColor = Color(0xFF333333);
    const Color pillGray = Color(0xFFF0EFF5);

    if (device == null) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: primaryPurple)),
      );
    }

    final double screenHeight = MediaQuery.of(context).size.height;
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double appBarHeight = kToolbarHeight;
    final double safeBodyHeight = screenHeight - statusBarHeight - appBarHeight;
    final bool isLocked = provider.isLoading || device.isOperating;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              device.deviceName,
              style: const TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text('ID: ${device.deviceId}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: primaryPurple),
            onPressed: () {
              context.push('/device_setting/$deviceId');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ==============================
            // 1. 顶部数据概况卡片 (今日与平均)
            // ==============================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryPurple,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: primaryPurple.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('今日如厕', style: TextStyle(fontSize: 14, color: Colors.white70)),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                device.todayTimes,
                                style: const TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                              const Text('次', style: TextStyle(fontSize: 14, color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('平均时长', style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                device.averageSeconds,
                                style: const TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  height: 1,
                                ),
                              ),
                              const Text('秒', style: TextStyle(fontSize: 14, color: textColor)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ==============================
            // 2. 设备图片及状态标签
            // ==============================
            Image.asset(
              'assets/images/product-pic.png',
              width: 120,
              height: 120,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.devices, size: 100, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(color: primaryPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(
                device.executeAction.label,
                style: const TextStyle(color: primaryPurple, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // ==============================
            // 3. 控制面板与卡片容器
            // ==============================
            Container(
              height: safeBodyHeight,
              width: double.infinity,
              padding: const EdgeInsets.only(left: 20, right: 20, top: 25, bottom: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, -4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 模式选择药丸按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildModePill(
                        title: '自动\n模式',
                        icon: Icons.autorenew_rounded,
                        isActive: device.workMode == WorkMode.auto,
                        activeColor: primaryPurple,
                        inactiveColor: pillGray,
                        onTap: () => provider.setMode(WorkMode.auto),
                      ),
                      _buildModePill(
                        title: '勿扰\n模式',
                        icon: Icons.nightlight_round,
                        isActive: device.isDndEnabled,
                        activeColor: primaryPurple,
                        inactiveColor: pillGray,
                        onTap: () => provider.toggleDnd(false),
                      ),
                      _buildModePill(
                        title: '定时\n模式',
                        icon: Icons.timer_rounded,
                        isActive: device.workMode == WorkMode.timer,
                        activeColor: primaryPurple,
                        inactiveColor: pillGray,
                        onTap: () => provider.setMode(WorkMode.timer),
                      ),
                      _buildModePill(
                        title: '手动\n模式',
                        icon: Icons.touch_app_rounded,
                        isActive: device.workMode == WorkMode.manual,
                        activeColor: primaryPurple,
                        inactiveColor: pillGray,
                        onTap: () => provider.setMode(WorkMode.manual),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // 紫色控制操作区域卡片
                  Container(
                    // 修改：减小水平内边距以容纳4个按钮
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
                    decoration: BoxDecoration(
                      color: primaryPurple,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: primaryPurple.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      // 修改：改为 spaceEvenly 使4个按钮分布更均匀
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          context,
                          '清理',
                          Icons.cleaning_services_rounded,
                          isLocked ? null : () => provider.executeAction(ExecuteAction.cleaning),
                          isLocked: isLocked,
                        ),
                        _buildActionButton(
                          context,
                          '抚平',
                          Icons.blur_on_rounded,
                          isLocked ? null : () => provider.executeAction(ExecuteAction.smoothing),
                          isLocked: isLocked,
                        ),
                        _buildActionButton(
                          context,
                          '除臭',
                          device.isPlasmaEnabled ? Icons.bubble_chart_rounded : Icons.bubble_chart_outlined,
                          provider.isLoading ? null : () => provider.togglePlasma(),
                          isLocked: provider.isLoading,
                        ),
                        _buildActionButton(
                          context,
                          '童锁',
                          device.isChildLockEnabled ? Icons.lock_rounded : Icons.lock_open_rounded,
                          provider.isLoading ? null : () => provider.toggleChildLock(),
                          isLocked: provider.isLoading,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 今日设备运行日志卡片
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9FC),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '今日运行动态',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: device.logs.isEmpty
                                ? const Center(
                                    child: Text('暂无相关动态', style: TextStyle(fontSize: 13, color: Colors.grey)),
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: device.logs.length,
                                    physics: const BouncingScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      final log = device.logs[index];
                                      final timeStr =
                                          "${log.time.hour.toString().padLeft(2, '0')}:${log.time.minute.toString().padLeft(2, '0')}";
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 10.0),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                color: primaryPurple,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '$timeStr  ${log.content}',
                                              style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModePill({
    required String title,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 75,
        height: 135,
        decoration: BoxDecoration(
          color: isActive ? activeColor : inactiveColor,
          borderRadius: BorderRadius.circular(38),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(6),
              height: 60,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Center(child: Icon(icon, color: isActive ? activeColor : Colors.grey, size: 28)),
            ),
            const Spacer(),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF666666),
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback? onTap, {
    bool isLocked = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isLocked ? 0.5 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(icon, color: const Color(0xFF917CEE), size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
