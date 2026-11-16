import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/features/device/products/litter_box/models/device_thing_model.dart';
import 'package:fullxpet/features/device/products/litter_box/viewmodels/litter_box_viewmodel.dart';

class LitterBoxControlPanel extends StatelessWidget {
  final bool showPlasmaAction;
  final bool showEmptyAction;

  const LitterBoxControlPanel({super.key, this.showPlasmaAction = false, this.showEmptyAction = true});

  static const Color _primary = Color(0xFF917CEE);
  static const Color _primaryLight = Color(0xFFF3F0FF);
  static const Color _bgPage = Color(0xFFF9F9FC);
  static const Color _pillGray = Color(0xFFF0EFF5);
  static const Color _online = Color(0xFF8CC152);
  static const Color _textMain = Color(0xFF333333);
  static const Color _textSub = Color(0xFF666666);
  static const Color _textMuted = Color(0xFF999999);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final vm = context.watch<LitterBoxViewModel>();
    final isBusy = vm.isLoading || vm.isOperating;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '工作模式',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textSub),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(color: _primaryLight, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  vm.modeSubParamText,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildModePill(
                title: s.autoMode,
                icon: Icons.autorenew_rounded,
                isActive: vm.workMode == WorkMode.auto && !vm.isDndEnabled,
                onTap: () => vm.setWorkMode(WorkMode.auto),
              ),
              const SizedBox(width: 8),
              _buildModePill(
                title: s.dndMode,
                icon: Icons.nightlight_round,
                isActive: vm.isDndEnabled,
                onTap: () => vm.toggleDnd(),
              ),
              const SizedBox(width: 8),
              _buildModePill(
                title: s.timerMode,
                icon: Icons.schedule_rounded,
                isActive: vm.workMode == WorkMode.timer && !vm.isDndEnabled,
                onTap: () => vm.setWorkMode(WorkMode.timer),
              ),
              const SizedBox(width: 8),
              _buildModePill(
                title: s.manualMode,
                icon: Icons.touch_app_rounded,
                isActive: vm.workMode == WorkMode.manual && !vm.isDndEnabled,
                onTap: () => vm.setWorkMode(WorkMode.manual),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: _primary.withValues(alpha: 0.24), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDockAction(
                  label: s.actionClean,
                  icon: Icons.cleaning_services_rounded,
                  isLocked: isBusy,
                  onTap: isBusy ? null : () => vm.executeAction(ExecuteAction.cleaning),
                ),
                _buildDockAction(
                  label: s.actionSmooth,
                  icon: Icons.waves_rounded,
                  isLocked: isBusy,
                  onTap: isBusy ? null : () => vm.executeAction(ExecuteAction.smoothing),
                ),
                if (showEmptyAction)
                  _buildDockAction(
                    label: s.actionEmptyLitter,
                    icon: Icons.delete_sweep_rounded,
                    isLocked: isBusy,
                    onTap: isBusy ? null : () => vm.executeAction(ExecuteAction.emptying),
                  ),
                if (showPlasmaAction)
                  _buildDockAction(
                    label: vm.isPlasmaEnabled ? '净味开' : s.actionDeodorize,
                    icon: vm.isPlasmaEnabled ? Icons.auto_awesome : Icons.bubble_chart_outlined,
                    isHighlighted: vm.isPlasmaEnabled,
                    isLocked: vm.isLoading,
                    onTap: vm.isLoading ? null : () => vm.togglePlasma(),
                  ),
                _buildDockAction(
                  label: vm.isChildLockEnabled ? '已锁定' : s.actionChildLock,
                  icon: vm.isChildLockEnabled ? Icons.lock_rounded : Icons.lock_open_rounded,
                  isHighlighted: vm.isChildLockEnabled,
                  isLocked: vm.isLoading,
                  onTap: vm.isLoading ? null : () => vm.toggleChildLock(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: _bgPage, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.todayLogs,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _textMain),
                    ),
                    const Text('实时同步 MQTT', style: TextStyle(fontSize: 10, color: _textMuted)),
                  ],
                ),
                const SizedBox(height: 10),
                if (vm.logs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(s.noLogs, style: const TextStyle(fontSize: 12, color: _textMuted)),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: vm.logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final log = vm.logs[index];
                      final timeStr =
                          "${log.time.hour.toString().padLeft(2, '0')}:${log.time.minute.toString().padLeft(2, '0')}";

                      String parsedContent = '';
                      if (log.isAction) {
                        try {
                          final action = ExecuteAction.values.byName(log.content);
                          parsedContent = action.getLocalizedLabel(s);
                        } catch (_) {
                          parsedContent = log.content;
                        }
                      } else {
                        final seconds = int.tryParse(log.content) ?? log.content;
                        parsedContent = s.catToiletLog(seconds);
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF0EFF5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: log.isAction ? const Color(0xFFECFDF5) : _primaryLight,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      log.isAction ? Icons.cleaning_services_rounded : Icons.pets_rounded,
                                      size: 12,
                                      color: log.isAction ? _online : _primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      parsedContent,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _textMain,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              timeStr,
                              style: const TextStyle(fontSize: 11, color: _textMuted, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModePill({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 104,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isActive ? _primary : _pillGray,
            borderRadius: BorderRadius.circular(28),
            boxShadow: isActive
                ? [BoxShadow(color: _primary.withValues(alpha: 0.26), blurRadius: 12, offset: const Offset(0, 4))]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(icon, color: isActive ? _primary : Colors.grey.shade400, size: 22),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isActive ? Colors.white : _textSub,
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDockAction({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    bool isHighlighted = false,
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: isHighlighted ? Border.all(color: const Color(0xFFFCD34D), width: 2) : null,
              ),
              child: Icon(icon, color: _primary, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isHighlighted ? const Color(0xFFFDE68A) : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
