import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/widgets/responsive_layout.dart';
import 'package:fullxpet/features/device/feeder/models/feeder_thing_model.dart';
import '../viewmodels/feeder_viewmodel.dart';

class FeederManagerPage extends StatelessWidget {
  final String deviceId;
  const FeederManagerPage({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FeederViewModel()..initDevice(deviceId),
      child: const _FeederManagerView(),
    );
  }
}

class _FeederManagerView extends StatelessWidget {
  const _FeederManagerView();

  static const Color _primary = Color(0xFF917CEE);
  static const Color _bg = Color(0xFFF9F9FC);
  static const Color _cardBg = Colors.white;
  static const Color _textMain = Color(0xFF333333);
  static const Color _textSub = Color(0xFF888888);
  static const Color _online = Color(0xFF8CC152);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FeederViewModel>();
    final device = vm.device;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textMain, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text(
              device?.deviceName.isNotEmpty == true ? device!.deviceName : 'PETLUX AI Feeder',
              style: const TextStyle(color: _textMain, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text('ID: ${device?.displayId ?? "BATCH-88219"}', style: const TextStyle(color: _textSub, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: _primary),
            onPressed: () => _showDeviceSettingsSheet(context, vm),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveFormContainer(
          maxWidth: 600,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. 摄像头/AI 猫脸识别视口
                _buildMediaViewport(vm),
                const SizedBox(height: 14),

                // 2. 推杆限位状态反馈卡
                _buildDoorStatusCard(vm),
                const SizedBox(height: 14),

                // 3. 控制面板（模式切换、手动推杆、模式说明）
                _buildControlBoard(context, vm),
                const SizedBox(height: 14),

                // 4. 快捷辅助卡片（童锁直控）
                _buildQuickToolsCard(vm),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 摄像头与视口 ---
  Widget _buildMediaViewport(FeederViewModel vm) {
    String visionStatus;
    switch (vm.currentMode) {
      case FeederMode.open:
        visionStatus = 'AI 视觉待命 (敞开)';
        break;
      case FeederMode.timer:
        visionStatus = '定时待命中';
        break;
      case FeederMode.faceAi:
        visionStatus = '猫脸识别实时检测中';
        break;
    }

    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF18181E),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: _online, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(visionStatus, style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ],
                ),
              ),
            ),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _primary.withValues(alpha: 0.7), width: 1.5),
              ),
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(6)),
                child: const Text(
                  'CAT FACE AI',
                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const Positioned(
              bottom: 30,
              child: Text(
                '视频预览与识别插槽',
                style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 14,
              child: Row(
                children: [
                  _buildMediaBtn(Icons.camera_alt_outlined, () {}),
                  const SizedBox(width: 8),
                  _buildMediaBtn(Icons.fullscreen_rounded, () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  // --- 推杆限位状态反馈卡 ---
  Widget _buildDoorStatusCard(FeederViewModel vm) {
    final isDispensed = vm.isDoorDispensed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.door_sliding_outlined, color: _primary, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '推杆限位状态',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textMain),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isDispensed ? '推杆已推出，仓口敞开' : '推杆已收回，仓口闭合',
                    style: const TextStyle(fontSize: 11, color: _textSub),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDispensed ? const Color(0xFFE8F5E9) : const Color(0xFFF0F0F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isDispensed ? '已推出 (开)' : '已收回 (关)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDispensed ? _online : const Color(0xFF777777),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 控制面板 ---
  Widget _buildControlBoard(BuildContext context, FeederViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.025), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              '工作模式',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textSub),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _buildModePill('敞开模式', Icons.lock_open_rounded, vm.currentMode == FeederMode.open, () {
                vm.switchMode(FeederMode.open);
              }),
              const SizedBox(width: 8),
              _buildModePill('定时出粮', Icons.schedule_rounded, vm.currentMode == FeederMode.timer, () {
                vm.switchMode(FeederMode.timer);
              }),
              const SizedBox(width: 8),
              _buildModePill('猫脸识别', Icons.pets_rounded, vm.currentMode == FeederMode.faceAi, () {
                vm.switchMode(FeederMode.faceAi);
              }),
            ],
          ),
          const SizedBox(height: 16),

          // 敞开模式下手动的推杆开关
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: vm.currentMode == FeederMode.open ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFECECF2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vm.isDoorDispensed ? '出粮推杆：已推出出粮' : '出粮推杆：已收回关闭',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textMain),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vm.isDoorDispensed ? '点击切换将电机收回闭合' : '点击切换将电机推出出粮',
                        style: const TextStyle(fontSize: 11, color: _textSub),
                      ),
                    ],
                  ),
                  Switch(
                    value: vm.isDoorDispensed,
                    activeThumbColor: _primary,
                    onChanged: (_) => vm.toggleFeedSwitch(),
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),

          _buildModeDetailPanel(context, vm),
        ],
      ),
    );
  }

  Widget _buildModePill(String title, IconData icon, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 96,
          decoration: BoxDecoration(
            color: isActive ? _primary : const Color(0xFFF0EFF5),
            borderRadius: BorderRadius.circular(24),
            boxShadow: isActive
                ? [BoxShadow(color: _primary.withValues(alpha: 0.28), blurRadius: 14, offset: const Offset(0, 6))]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(icon, color: isActive ? _primary : Colors.grey.shade600, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? Colors.white : const Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeDetailPanel(BuildContext context, FeederViewModel vm) {
    String title;
    String desc;
    String linkText;
    VoidCallback? onLinkTap;

    switch (vm.currentMode) {
      case FeederMode.open:
        title = '敞开模式说明';
        desc = '仓口保持常开，可通过上方开关直接推粮或收回';
        linkText = '出粮开关';
        onLinkTap = () => vm.toggleFeedSwitch();
        break;
      case FeederMode.timer:
        title = '定时出粮计划 (${vm.timerRanges.length}个时段)';
        desc = '在设定时间段内推杆敞开推粮，结束后自动收回';
        linkText = '配置时段';
        onLinkTap = () => _showTimerScheduleSheet(context, vm);
        break;
      case FeederMode.faceAi:
        title = '猫脸识别智能出粮';
        desc = '摄像头识别到目标猫咪时自动推开，离开后收回';
        linkText = '识别灵敏度';
        onLinkTap = () {};
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(18)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textMain),
                ),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: _textSub)),
              ],
            ),
          ),
          InkWell(
            onTap: onLinkTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                linkText,
                style: const TextStyle(fontSize: 12, color: _primary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 快捷辅助卡片（童锁） ---
  Widget _buildQuickToolsCard(FeederViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(vm.isChildLock ? Icons.lock_rounded : Icons.lock_open_rounded, color: _primary, size: 18),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '童锁保护',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textMain),
                  ),
                  SizedBox(height: 2),
                  Text('开启后物理按键锁定，防止误触', style: TextStyle(fontSize: 11, color: _textSub)),
                ],
              ),
            ],
          ),
          Switch(value: vm.isChildLock, activeThumbColor: _primary, onChanged: (_) => vm.toggleChildLock()),
        ],
      ),
    );
  }

  // ================= 弹窗 1：定时出粮时间段排期 (BottomSheet) =================
  void _showTimerScheduleSheet(BuildContext context, FeederViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final ranges = vm.timerRanges;

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
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textMain),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, color: _primary, size: 26),
                          onPressed: () async {
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

                            final startStr =
                                "${startPicked.hour.toString().padLeft(2, '0')}:${startPicked.minute.toString().padLeft(2, '0')}";
                            final endStr =
                                "${endPicked.hour.toString().padLeft(2, '0')}:${endPicked.minute.toString().padLeft(2, '0')}";

                            await vm.addTimerRange(startStr, endStr);
                            setSheetState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (ranges.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 36),
                        child: Text('暂无计划，点击右上角添加区间', style: TextStyle(fontSize: 13, color: _textSub)),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: ranges.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
                          itemBuilder: (context, index) {
                            final range = ranges[index];
                            return Slidable(
                              key: ValueKey('${range.start}-${range.end}-$index'),
                              endActionPane: ActionPane(
                                motion: const ScrollMotion(),
                                extentRatio: 0.22,
                                children: [
                                  SlidableAction(
                                    onPressed: (_) async {
                                      await vm.removeTimerRange(index);
                                      setSheetState(() {});
                                    },
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                    icon: Icons.delete_outline,
                                  ),
                                ],
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.schedule_rounded, color: _primary, size: 20),
                                ),
                                title: Text(
                                  '${range.start}  至  ${range.end}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textMain),
                                ),
                                subtitle: const Text(
                                  '到达时间推出推杆，结束时自动收回',
                                  style: TextStyle(fontSize: 11, color: _textSub),
                                ),
                                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                              ),
                            );
                          },
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

  // ================= 弹窗 2：设备参数与网络运维 (BottomSheet) =================
  void _showDeviceSettingsSheet(BuildContext context, FeederViewModel vm) {
    final dev = vm.device;
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
                  '设备与网络参数',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textMain),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('设备名称', dev?.deviceName ?? 'PETLUX AI Feeder'),
                _buildInfoRow('设备序列号', dev?.displayId ?? '-'),
                _buildInfoRow('Wi-Fi 信号', vm.wifiRssi),
                _buildInfoRow('IP 地址', vm.wifiIp),
                _buildInfoRow('MAC 地址', vm.wifiMac),
                _buildInfoRow('固件版本', vm.firmwareVersion.isNotEmpty ? vm.firmwareVersion : 'v1.0.0'),
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
          Text(label, style: const TextStyle(fontSize: 13, color: _textSub)),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textMain),
          ),
        ],
      ),
    );
  }
}
