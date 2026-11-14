import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/widgets/responsive_layout.dart';
import 'package:fullxpet/features/device/products/litter_box/v3/models/device_thing_model.dart';
import 'package:fullxpet/features/device/products/litter_box/viewmodels/litter_box_viewmodel.dart';
import 'package:fullxpet/features/device/widgets/device_detail_app_bar.dart';
import 'package:fullxpet/routes/app_router.dart';

typedef WidgetList = List<Widget>;

class LitterBoxManageScaffold extends StatelessWidget {
  final String deviceId;
  final String modelBadge;
  final bool showPlasmaFeature;
  final bool showEmptyAction;
  final Widget? mediaSlot;
  final WidgetList sensorSlots;

  const LitterBoxManageScaffold({
    super.key,
    required this.deviceId,
    required this.modelBadge,
    this.showPlasmaFeature = false,
    this.showEmptyAction = true,
    this.mediaSlot,
    this.sensorSlots = const [],
  });

  static const Color _bgPage = Color(0xFFF9F9FC);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LitterBoxViewModel>();

    return Scaffold(
      backgroundColor: _bgPage,
      appBar: DeviceDetailAppBar(
        title: vm.deviceName,
        modelBadge: modelBadge,
        subtitle: 'ID: ${vm.displayId}',
        onSettingTap: () {
          context.push(AppRoutes.deviceSettingPath(deviceId));
        },
      ),
      body: SafeArea(
        child: ResponsiveFormContainer(
          maxWidth: 600,
          child: RefreshIndicator(
            color: const Color(0xFF917CEE),
            onRefresh: () => vm.initDevice(deviceId),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (vm.isShitBinNearlyFull) ...[_buildAlertBanner(vm.shitWeightGrams), const SizedBox(height: 14)],
                  if (mediaSlot != null) ...[mediaSlot!, const SizedBox(height: 14)],
                  LitterBoxHeroCard(showPlasmaBadge: showPlasmaFeature),
                  const SizedBox(height: 14),
                  for (final slotWidget in sensorSlots) ...[slotWidget, const SizedBox(height: 14)],
                  LitterBoxControlPanel(showPlasmaAction: showPlasmaFeature, showEmptyAction: showEmptyAction),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertBanner(int grams) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFF37474).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF37474), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '集便仓即将满仓 (${grams}g)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
                ),
                const SizedBox(height: 2),
                const Text('请及时更换垃圾袋，避免影响自动清理', style: TextStyle(fontSize: 10, color: Color(0xFFEF4444))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LitterBoxHeroCard extends StatelessWidget {
  final bool showPlasmaBadge;
  const LitterBoxHeroCard({super.key, this.showPlasmaBadge = false});

  static const Color _primary = Color(0xFF917CEE);
  static const Color _primaryLight = Color(0xFFF3F0FF);
  static const Color _bgPage = Color(0xFFF9F9FC);
  static const Color _online = Color(0xFF8CC152);
  static const Color _offline = Color(0xFFF39191);
  static const Color _textMain = Color(0xFF333333);
  static const Color _textSub = Color(0xFF666666);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final vm = context.watch<LitterBoxViewModel>();
    final isOnline = vm.isOnline;
    final statusText = isOnline ? vm.currentAction.getLocalizedLabel(s) : s.offline;

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
                  decoration: BoxDecoration(color: _bgPage, borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_outlined, size: 13, color: _primary),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '防夹红外/安全保护',
                          style: TextStyle(fontSize: 11, color: _textSub),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        '开启中',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _online),
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
                  context.push(AppRoutes.deviceWeighingPath(vm.deviceId));
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
