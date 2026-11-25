import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/features/device/products/litter_box/viewmodels/litter_box_viewmodel.dart';

class LitterBoxWeighingCard extends StatelessWidget {
  const LitterBoxWeighingCard({super.key});

  static const Color _bgPage = Color(0xFFF9F9FC);
  static const Color _online = Color(0xFF8CC152);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _danger = Color(0xFFF37474);
  static const Color _textMain = Color(0xFF333333);
  static const Color _textSub = Color(0xFF666666);

  ({String text, Color bg, Color fg, Color bar}) _resolveLitterStatus(int grams) {
    if (grams < LitterBoxViewModel.litterRecommendedMinGrams) {
      return (text: '偏少', bg: const Color(0xFFFEF3C7), fg: const Color(0xFFD97706), bar: _warning);
    }
    if (grams > LitterBoxViewModel.litterRecommendedMaxGrams) {
      return (text: '偏多', bg: const Color(0xFFFEE2E2), fg: _danger, bar: _danger);
    }
    return (text: '适宜', bg: const Color(0xFFDCFCE7), fg: _online, bar: _online);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LitterBoxViewModel>();
    final int litterG = vm.litterWeightGrams;
    final int shitG = vm.shitWeightGrams;
    final litterStatus = _resolveLitterStatus(litterG);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF181828).withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '设备重量',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textSub),
          ),
          const SizedBox(height: 8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(color: _bgPage, borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 18,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '盆内余砂',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textSub),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: litterStatus.bg,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  litterStatus.text,
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: litterStatus.fg),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildWeightValue(litterG),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: vm.litterPercent,
                            minHeight: 5,
                            backgroundColor: const Color(0xFFE5E7EB),
                            valueColor: AlwaysStoppedAnimation(litterStatus.bar),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(color: _bgPage, borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: 18,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '集便仓',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textSub),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildWeightValue(shitG),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightValue(int grams) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$grams',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _textMain, height: 1),
        ),
        const SizedBox(width: 2),
        const Text(
          'g',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _textSub),
        ),
      ],
    );
  }
}
