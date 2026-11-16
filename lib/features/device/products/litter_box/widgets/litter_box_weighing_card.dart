import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/features/device/products/litter_box/viewmodels/litter_box_viewmodel.dart';
import 'package:fullxpet/routes/app_router.dart';

class LitterBoxWeighingCard extends StatelessWidget {
  const LitterBoxWeighingCard({super.key});

  static const Color _primary = Color(0xFF917CEE);
  static const Color _primaryLight = Color(0xFFF3F0FF);
  static const Color _bgPage = Color(0xFFF9F9FC);
  static const Color _online = Color(0xFF8CC152);
  static const Color _danger = Color(0xFFF37474);
  static const Color _textMain = Color(0xFF333333);
  static const Color _textSub = Color(0xFF666666);
  static const Color _textMuted = Color(0xFF999999);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LitterBoxViewModel>();
    final int litterG = vm.litterWeightGrams;
    final int litterPct = (vm.litterPercent * 100).round();
    final int shitG = vm.shitWeightGrams;
    final int shitPct = (vm.shitPercent * 100).round();
    final bool isBinAlert = vm.isShitBinNearlyFull;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDE9FE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF181828).withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(color: _primaryLight, borderRadius: BorderRadius.circular(7)),
                    child: const Icon(Icons.scale_rounded, size: 14, color: _primary),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '实时称重感知看板',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _textMain),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  context.push(AppRoutes.deviceWeighingPath(vm.deviceId), extra: vm);
                },
                child: const Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 12, color: _primary),
                    SizedBox(width: 3),
                    Text(
                      '称重校准',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _primary),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 14, color: _primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _bgPage, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '盆内余砂',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textSub),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: litterG < 1800 ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              litterG < 1800 ? '偏少 $litterPct%' : '充足 $litterPct%',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: litterG < 1800 ? const Color(0xFFD97706) : _online,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$litterG',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textMain),
                          ),
                          const SizedBox(width: 2),
                          const Text(
                            'g',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _textSub),
                          ),
                          const Spacer(),
                          Text(
                            '≈ ${(litterG / 1000.0).toStringAsFixed(1)}kg',
                            style: const TextStyle(fontSize: 10, color: _textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: vm.litterPercent,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: const AlwaysStoppedAnimation(_primary),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text('建议保持在 2500g ~ 4500g', style: TextStyle(fontSize: 9, color: _textMuted)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _bgPage, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '集便仓重量',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textSub),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isBinAlert ? const Color(0xFFFEE2E2) : _primaryLight,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              isBinAlert ? '即将满仓 $shitPct%' : '已用 $shitPct%',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isBinAlert ? _danger : _primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$shitG',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textMain),
                          ),
                          const SizedBox(width: 2),
                          const Text(
                            'g',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _textSub),
                          ),
                          const Spacer(),
                          const Text('/ 2000g上限', style: TextStyle(fontSize: 10, color: _textMuted)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: vm.shitPercent,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: AlwaysStoppedAnimation(isBinAlert ? _danger : _online),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isBinAlert ? '请尽快清理集便仓' : '集便仓余量充足',
                        style: TextStyle(fontSize: 9, color: isBinAlert ? _danger : _textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
