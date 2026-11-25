import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/features/device/products/litter_box/viewmodels/litter_box_viewmodel.dart';

class LitterBoxHeroCard extends StatelessWidget {
  final bool showPlasmaBadge;
  const LitterBoxHeroCard({super.key, this.showPlasmaBadge = false});

  static const Color _primary = Color(0xFF917CEE);
  static const Color _primaryLight = Color(0xFFF3F0FF);
  static const Color _bgPage = Color(0xFFF9F9FC);
  static const Color _online = Color(0xFF8CC152);
  static const Color _offline = Color(0xFFF39191);
  static const Color _danger = Color(0xFFF37474);
  static const Color _textMain = Color(0xFF333333);
  static const Color _textSub = Color(0xFF666666);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final vm = context.watch<LitterBoxViewModel>();
    final isOnline = vm.isOnline;
    final statusText = vm.resolveStatusLabel(s);
    final bool? buckleFastened = vm.isBuckleFastened;
    final bool isBuckleLoose = buckleFastened == false;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF181828).withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 94,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: _bgPage, borderRadius: BorderRadius.circular(20)),
                      child: vm.imageUrl.isNotEmpty
                          ? Image.network(
                              vm.imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(Icons.pets_rounded, size: 40, color: _primary),
                            )
                          : const Icon(Icons.pets_rounded, size: 40, color: _primary),
                    ),
                    if (showPlasmaBadge && isOnline && vm.isPlasmaEnabled)
                      Positioned(
                        top: -5,
                        right: -5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [_primary, Color(0xFF6366F1)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, size: 9, color: Colors.white),
                              SizedBox(width: 2),
                              Text(
                                '净味中',
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isOnline ? _primaryLight : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: isOnline ? _online : _offline, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: isOnline ? _primary : _textSub,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        decoration: BoxDecoration(
                          color: _primary,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.todayToilet,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
                              maxLines: 1,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${vm.todayTimes}',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                ),
                                Text(s.timesUnit, style: const TextStyle(fontSize: 11, color: Colors.white)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        decoration: BoxDecoration(
                          color: _bgPage,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFF0EFF5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.averageDuration,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textSub),
                              maxLines: 1,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${vm.averageSeconds}',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: _textMain,
                                    height: 1,
                                  ),
                                ),
                                Text(s.secondsUnit, style: const TextStyle(fontSize: 11, color: _textSub)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isBuckleLoose ? const Color(0xFFFEF2F2) : _bgPage,
                    borderRadius: BorderRadius.circular(12),
                    border: isBuckleLoose ? Border.all(color: const Color(0xFFFECACA)) : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isBuckleLoose ? Icons.warning_amber_rounded : Icons.lock_outline_rounded,
                        size: 13,
                        color: isBuckleLoose ? _danger : _primary,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '卡扣状态',
                          style: TextStyle(fontSize: 11, color: isBuckleLoose ? const Color(0xFFB91C1C) : _textSub),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        buckleFastened == null ? '--' : (buckleFastened ? '已扣紧' : '未扣紧'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: buckleFastened == null ? _textSub : (buckleFastened ? _online : _danger),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
