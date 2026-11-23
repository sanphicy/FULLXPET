import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/widgets/app_dialogs.dart';
import '../models/feeder_thing_model.dart';
import '../viewmodels/feeder_viewmodel.dart';

class FeederControlBoard extends StatelessWidget {
  const FeederControlBoard({super.key});

  static const Color _primary = Color(0xFF917CEE);
  static const Color _bg = Color(0xFFF9F9FC);
  static const Color _cardBg = Colors.white;
  static const Color _textMain = Color(0xFF333333);
  static const Color _textSub = Color(0xFF888888);

  Future<void> _handleSwitchMode(BuildContext context, FeederViewModel vm, FeederMode mode) async {
    vm.switchMode(mode);
  }

  Future<void> _handleToggleFeed(BuildContext context, FeederViewModel vm) async {
    vm.toggleFeedSwitch();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FeederViewModel>();

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
                _handleSwitchMode(context, vm, FeederMode.open);
              }),
              const SizedBox(width: 8),
              _buildModePill('红外模式', Icons.sensors_rounded, vm.currentMode == FeederMode.infrared, () {
                _handleSwitchMode(context, vm, FeederMode.infrared);
              }),
              const SizedBox(width: 8),
              _buildModePill('猫脸识别', Icons.pets_rounded, vm.currentMode == FeederMode.faceAi, () {
                _handleSwitchMode(context, vm, FeederMode.faceAi);
              }),
            ],
          ),
          const SizedBox(height: 16),
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
                    onChanged: (_) => _handleToggleFeed(context, vm),
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
        onLinkTap = () => _handleToggleFeed(context, vm);
        break;
      case FeederMode.infrared:
        title = '红外模式说明';
        desc = '红外感应到宠物靠近时自动推开出粮，离开后自动收回';
        linkText = '';
        onLinkTap = null;
        break;
      case FeederMode.faceAi:
        title = '猫脸识别智能出粮';
        desc = '摄像头识别到目标猫咪时自动推开，离开后收回';
        linkText = '';
        onLinkTap = null;
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
          if (linkText.isNotEmpty)
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
}
