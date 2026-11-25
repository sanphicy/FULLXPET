import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/widgets/responsive_layout.dart';
import 'package:fullxpet/features/device/models/device_log.dart';
import 'package:fullxpet/features/device/products/litter_box/models/device_thing_model.dart';
import 'package:fullxpet/features/device/products/litter_box/viewmodels/litter_box_viewmodel.dart';
import 'package:fullxpet/features/device/widgets/device_detail_app_bar.dart';
import 'package:fullxpet/routes/app_router.dart';
import 'litter_box_control_panel.dart';
import 'litter_box_hero_card.dart';

typedef WidgetList = List<Widget>;

class LitterBoxManageScaffold extends StatefulWidget {
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

  @override
  State<LitterBoxManageScaffold> createState() => _LitterBoxManageScaffoldState();
}

class _LitterBoxManageScaffoldState extends State<LitterBoxManageScaffold> {
  static const Color _primary = Color(0xFF917CEE);
  static const Color _primaryLight = Color(0xFFF3F0FF);
  static const Color _online = Color(0xFF8CC152);
  static const Color _offline = Color(0xFFF39191);
  static const Color _danger = Color(0xFFF37474);
  static const Color _bgPage = Color(0xFFF9F9FC);
  static const Color _textMain = Color(0xFF333333);
  static const Color _textSub = Color(0xFF666666);
  static const Color _textMuted = Color(0xFF8E8E9A);

  bool _showStickyBar = false;

  bool _handleScrollNotification(ScrollNotification notification, LitterBoxViewModel vm) {
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification is ScrollUpdateNotification || notification is OverscrollNotification) {
      final metrics = notification.metrics;
      const double stickyThreshold = 125;
      final bool shouldShow = metrics.pixels > stickyThreshold;
      if (shouldShow != _showStickyBar && mounted) {
        setState(() => _showStickyBar = shouldShow);
      }
      if (metrics.maxScrollExtent > 0 && metrics.pixels >= metrics.maxScrollExtent - 200) {
        vm.loadMoreTodayLogs();
      }
    }
    return false;
  }

  String _formatLogTime(BuildContext context, DateTime time) {
    final isZh = Localizations.localeOf(context).languageCode.toLowerCase() == 'zh';
    final mm = time.minute.toString().padLeft(2, '0');
    if (!isZh) {
      return '${time.hour.toString().padLeft(2, '0')}:$mm';
    }
    final period = time.hour < 12 ? '上午' : '下午';
    final h12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
    return '$period $h12:$mm';
  }

  String _resolveLogContent(DeviceLog log, S s) {
    switch (log.type) {
      case DeviceLogType.executeAction:
        try {
          return ExecuteAction.values.byName(log.content).getLocalizedLabel(s);
        } catch (_) {
          return log.content;
        }
      case DeviceLogType.catToilet:
        final seconds = int.tryParse(log.content) ?? log.content;
        return s.catToiletLog(seconds);
      case DeviceLogType.catEntry:
        return '猫咪进入';
      case DeviceLogType.calibration:
        return s.weighingCalibration;
      case DeviceLogType.resetWifi:
        return s.resetWifi;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final vm = context.watch<LitterBoxViewModel>();
    final logs = vm.logs;

    return Scaffold(
      backgroundColor: _bgPage,
      appBar: DeviceDetailAppBar(
        title: vm.deviceName,
        modelBadge: widget.modelBadge,
        subtitle: 'ID: ${vm.displayId}',
        onSettingTap: () {
          context.push(AppRoutes.litterBoxSettingPath(widget.deviceId));
        },
      ),
      body: SafeArea(
        child: ResponsiveFormContainer(
          maxWidth: 600,
          child: Stack(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (n) => _handleScrollNotification(n, vm),
                child: CustomScrollView(
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (widget.mediaSlot != null) ...[widget.mediaSlot!, const SizedBox(height: 12)],
                            LitterBoxHeroCard(showPlasmaBadge: widget.showPlasmaFeature),
                            const SizedBox(height: 12),
                            for (final slotWidget in widget.sensorSlots) ...[slotWidget, const SizedBox(height: 12)],
                            LitterBoxControlPanel(
                              showPlasmaAction: widget.showPlasmaFeature,
                              showEmptyAction: widget.showEmptyAction,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 今日运行动态区块头
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(22, 16, 22, 10),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          s.todayLogs,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _textMain),
                        ),
                      ),
                    ),

                    // 日志主体：加载中 / 空态 / 时间线卡片列表
                    if (vm.isLoadingLogs && logs.isEmpty)
                      const SliverPadding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        sliver: SliverToBoxAdapter(
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
                            ),
                          ),
                        ),
                      )
                    else if (logs.isEmpty && !vm.hasMoreLogs)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 28),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFF0EFF5)),
                            ),
                            child: Center(
                              child: Text(s.noLogs, style: const TextStyle(fontSize: 12, color: _textMuted)),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList.separated(
                          itemCount: logs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) => _buildLogTimelineItem(context, logs[index], s),
                        ),
                      ),

                    // 底部翻页状态尾条
                    SliverToBoxAdapter(child: _buildLogsFooter(vm)),
                  ],
                ),
              ),

              // 下滑后自动吸顶的精简状态条（保留运行状态、卡扣状态与今日如厕次数）
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  ignoring: !_showStickyBar,
                  child: AnimatedOpacity(
                    opacity: _showStickyBar ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    child: _buildStickyStatusBar(vm, s),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStickyStatusBar(LitterBoxViewModel vm, S s) {
    final bool isOnline = vm.isOnline;
    final bool? buckleFastened = vm.isBuckleFastened;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        border: const Border(bottom: BorderSide(color: Color(0xFFEEEEF5))),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: isOnline ? _primaryLight : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
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
                Text(
                  vm.resolveStatusLabel(s),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isOnline ? _primary : _textSub),
                ),
              ],
            ),
          ),
          if (buckleFastened != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: buckleFastened ? const Color(0xFFF3F8EE) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                buckleFastened ? '卡扣已扣紧' : '卡扣未扣紧',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: buckleFastened ? _online : _danger),
              ),
            ),
          ],
          const Spacer(),
          Text(
            '${s.todayToilet} ${vm.todayTimes}${s.timesUnit}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textSub),
          ),
        ],
      ),
    );
  }

  Widget _buildLogTimelineItem(BuildContext context, DeviceLog log, S s) {
    final Color barColor = log.isCatEvent ? _primary : _online;
    final String timeStr = _formatLogTime(context, log.time);
    final String content = _resolveLogContent(log, s);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 62,
          child: Text(
            timeStr,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _textMuted),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF0EFF5)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF181828).withValues(alpha: 0.025),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 3.5,
                  height: 22,
                  decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    content,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textMain),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogsFooter(LitterBoxViewModel vm) {
    if (vm.isLoadingMoreLogs) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(0, 16, 0, 28),
        child: Center(
          child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _primary)),
        ),
      );
    }

    if (vm.hasMoreLogs) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 14, 0, 28),
        child: Center(
          child: GestureDetector(
            onTap: vm.loadMoreTodayLogs,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text('加载更多', style: TextStyle(fontSize: 12, color: _textMuted)),
            ),
          ),
        ),
      );
    }

    if (vm.logs.isNotEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(0, 14, 0, 28),
        child: Center(
          child: Text('已显示今日全部动态', style: TextStyle(fontSize: 11, color: Color(0xFFB4B4BF))),
        ),
      );
    }

    return const SizedBox(height: 28);
  }
}
