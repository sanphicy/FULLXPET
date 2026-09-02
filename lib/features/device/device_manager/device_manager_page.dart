import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fullxpet/routes/app_router.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/widgets/responsive_layout.dart';
import 'package:fullxpet/features/device/active_device_provider.dart';
import 'package:fullxpet/features/device/models/device_dto.dart';
import 'package:fullxpet/features/device/models/device_thing_model.dart';

class DeviceManagerPage extends StatelessWidget {
  final String deviceId;
  const DeviceManagerPage({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final provider = context.read<ActiveDeviceProvider>();

    const Color primaryPurple = Color(0xFF917CEE);
    const Color bgColor = Color(0xFFF9F9FC);
    const Color textColor = Color(0xFF333333);
    const Color pillGray = Color(0xFFF0EFF5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Selector<ActiveDeviceProvider, (String, String)>(
          selector: (_, vm) => (vm.currentDevice?.deviceName ?? '', vm.currentDevice?.displayId ?? ''),
          builder: (context, data, _) {
            return Column(
              children: [
                Text(
                  data.$1.isNotEmpty ? data.$1 : 'FULLXPET',
                  style: const TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text('ID: ${data.$2}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            );
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: primaryPurple),
            onPressed: () => context.push('/device_setting/$deviceId'),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveFormContainer(
          maxWidth: 600,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                // 1. 顶部今日与平均时长统计卡片（局部监听）
                Selector<ActiveDeviceProvider, (String, String)>(
                  selector: (_, vm) => (vm.currentDevice?.todayTimes ?? '0', vm.currentDevice?.averageSeconds ?? '0'),
                  builder: (context, stats, _) {
                    return Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: primaryPurple,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryPurple.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.todayToilet, style: const TextStyle(fontSize: 14, color: Colors.white70)),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      stats.$1,
                                      style: const TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1,
                                      ),
                                    ),
                                    Text(s.timesUnit, style: const TextStyle(fontSize: 14, color: Colors.white)),
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
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.averageDuration, style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      stats.$2,
                                      style: const TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                        height: 1,
                                      ),
                                    ),
                                    Text(s.secondsUnit, style: const TextStyle(fontSize: 14, color: textColor)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // 2. 设备展示图与当前状态标签（局部监听）
                Image.asset(
                  provider.currentDevice?.displayImage ?? 'assets/images/product-pic.png',
                  width: 110,
                  height: 110,
                  errorBuilder: (_, __, ___) => const Icon(Icons.devices, size: 90, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Selector<ActiveDeviceProvider, (ExecuteAction, bool)>(
                  selector: (_, vm) =>
                      (vm.currentDevice?.executeAction ?? ExecuteAction.idle, vm.currentDevice?.isOnline ?? false),
                  builder: (context, data, _) {
                    final action = data.$1;
                    final isOnline = data.$2;

                    final statusText = isOnline ? action.getLocalizedLabel(s) : s.offline;
                    final tagBgColor = isOnline
                        ? primaryPurple.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.15);
                    final tagTextColor = isOnline ? primaryPurple : Colors.grey.shade600;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(color: tagBgColor, borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        statusText,
                        style: TextStyle(color: tagTextColor, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // 3. 控制面板与动态日志卡片
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 15,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 模式选择药丸按钮（局部监听）
                      // 1. 模式选择药丸按钮区域：在每个 _buildModePill 之间增加间距或直接等分
                      Selector<ActiveDeviceProvider, (WorkMode, bool)>(
                        selector: (_, vm) =>
                            (vm.currentDevice?.workMode ?? WorkMode.auto, vm.currentDevice?.isDndEnabled ?? false),
                        builder: (context, state, _) {
                          final workMode = state.$1;
                          final isDnd = state.$2;
                          return Row(
                            children: [
                              _buildModePill(
                                title: s.autoMode,
                                icon: Icons.autorenew_rounded,
                                isActive: workMode == WorkMode.auto,
                                activeColor: primaryPurple,
                                inactiveColor: pillGray,
                                onTap: () => provider.setMode(WorkMode.auto),
                              ),
                              const SizedBox(width: 8),
                              _buildModePill(
                                title: s.dndMode,
                                icon: Icons.nightlight_round,
                                isActive: isDnd,
                                activeColor: primaryPurple,
                                inactiveColor: pillGray,
                                onTap: () => provider.toggleDnd(false),
                              ),
                              const SizedBox(width: 8),
                              _buildModePill(
                                title: s.timerMode,
                                icon: Icons.timer_rounded,
                                isActive: workMode == WorkMode.timer,
                                activeColor: primaryPurple,
                                inactiveColor: pillGray,
                                onTap: () => provider.setMode(WorkMode.timer),
                              ),
                              const SizedBox(width: 8),
                              _buildModePill(
                                title: s.manualMode,
                                icon: Icons.touch_app_rounded,
                                isActive: workMode == WorkMode.manual,
                                activeColor: primaryPurple,
                                inactiveColor: pillGray,
                                onTap: () => provider.setMode(WorkMode.manual),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // 紫色操作动作卡片（局部监听）
                      Selector<ActiveDeviceProvider, (bool, bool, bool, bool)>(
                        selector: (_, vm) => (
                          vm.isLoading,
                          vm.currentDevice?.isOperating ?? false,
                          vm.currentDevice?.isPlasmaEnabled ?? false,
                          vm.currentDevice?.isChildLockEnabled ?? false,
                        ),
                        builder: (context, state, _) {
                          final isBusy = state.$1 || state.$2;
                          final isPlasma = state.$3;
                          final isLock = state.$4;

                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                            decoration: BoxDecoration(
                              color: primaryPurple,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryPurple.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildActionButton(
                                  s.actionClean,
                                  Icons.cleaning_services_rounded,
                                  isBusy ? null : () => provider.executeAction(ExecuteAction.cleaning),
                                  isLocked: isBusy,
                                ),
                                _buildActionButton(
                                  s.actionSmooth,
                                  Icons.blur_on_rounded,
                                  isBusy ? null : () => provider.executeAction(ExecuteAction.smoothing),
                                  isLocked: isBusy,
                                ),
                                if (provider.currentDevice?.hasPlasma == true)
                                  _buildActionButton(
                                    s.actionDeodorize,
                                    isPlasma ? Icons.bubble_chart_rounded : Icons.bubble_chart_outlined,
                                    state.$1 ? null : () => provider.togglePlasma(),
                                    isLocked: state.$1,
                                  ),
                                _buildActionButton(
                                  s.actionChildLock,
                                  isLock ? Icons.lock_rounded : Icons.lock_open_rounded,
                                  state.$1 ? null : () => provider.toggleChildLock(),
                                  isLocked: state.$1,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // 今日动态日志列表（局部监听）
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 180),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9FC),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.todayLogs,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                            ),
                            const SizedBox(height: 12),
                            Selector<ActiveDeviceProvider, List<DeviceLog>>(
                              selector: (_, vm) => List<DeviceLog>.from(vm.currentDevice?.logs ?? []),
                              builder: (context, logs, _) {
                                if (logs.isEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 24),
                                    child: Center(
                                      child: Text(s.noLogs, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                    ),
                                  );
                                }
                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  itemCount: logs.length,
                                  itemBuilder: (context, index) {
                                    final log = logs[index];
                                    final timeStr =
                                        "${log.time.hour.toString().padLeft(2, '0')}:${log.time.minute.toString().padLeft(2, '0')}";

                                    String parsedContent = '';

                                    if (log.isAction) {
                                      // 动作：转回枚举直接调 getLocalizedLabel
                                      try {
                                        final action = ExecuteAction.values.byName(log.content);
                                        parsedContent = action.getLocalizedLabel(s);
                                      } catch (_) {
                                        parsedContent = log.content;
                                      }
                                    } else {
                                      // 如厕时长：直接调用带参文案
                                      final seconds = int.tryParse(log.content) ?? log.content;
                                      parsedContent = s.catToiletLog(seconds);
                                    }

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
                                            '$timeStr  $parsedContent',
                                            style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 120, // 保持舒适高度
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(34),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(5),
                height: 50,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Center(child: Icon(icon, color: isActive ? activeColor : Colors.grey, size: 24)),
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback? onTap, {bool isLocked = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isLocked ? 0.5 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(icon, color: const Color(0xFF917CEE), size: 24),
            ),
            const SizedBox(height: 6),
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
