import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/widgets/responsive_layout.dart';
import 'package:fullxpet/features/device/products/feeder/models/feeder_thing_model.dart';
import 'package:fullxpet/features/device/widgets/device_detail_app_bar.dart';
import 'package:fullxpet/routes/app_router.dart';
import '../viewmodels/feeder_viewmodel.dart';
import '../widgets/agora_video_widget.dart';
import '../widgets/feeder_control_board.dart';

class FeederManagerPage extends StatelessWidget {
  final String deviceId;
  const FeederManagerPage({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return const _FeederManagerView();
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

    return Scaffold(
      backgroundColor: _bg,
      appBar: DeviceDetailAppBar(
        title: vm.deviceName,
        modelBadge: 'AI',
        subtitle: 'ID: ${vm.displayId}',
        onSettingTap: () {
          if (vm.deviceId.isNotEmpty) {
            context.push(AppRoutes.feederSettingPath(vm.deviceId));
          }
        },
      ),
      body: SafeArea(
        child: ResponsiveFormContainer(
          maxWidth: 600,
          child: RefreshIndicator(
            color: _primary,
            onRefresh: () => vm.initDevice(vm.deviceId),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMediaViewport(vm),
                  const SizedBox(height: 14),
                  _buildDoorStatusCard(vm),
                  const SizedBox(height: 14),
                  const FeederControlBoard(),
                  const SizedBox(height: 14),
                  _buildQuickToolsCard(vm),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaViewport(FeederViewModel vm) {
    String visionStatus;
    switch (vm.currentMode) {
      case FeederMode.open:
        visionStatus = vm.isTimerEnabled ? 'AI 视觉待命 (敞开+定时)' : 'AI 视觉待命 (敞开)';
        break;
      case FeederMode.infrared:
        visionStatus = '红外感应待命中';
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: AgoraVideoWidget(
                  liveInfo: vm.liveInfo,
                  isLoading: vm.isLiveLoading,
                  errorMsg: vm.liveErrorMsg,
                  onRetry: () => vm.fetchLiveStreamInfo(),
                ),
              ),
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
}
