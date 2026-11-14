import 'package:flutter/material.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/features/device/device_provider.dart';

class DeviceCard extends StatelessWidget {
  final String deviceName;
  final String productName; // 如 "智能猫砂盆 3.0"
  final bool isOnline;
  final String imageUrl;
  final CardBadgeList badges; // 动态设备数据微摘要
  final bool isGridMode;
  final VoidCallback? onTap;

  const DeviceCard({
    super.key,
    required this.deviceName,
    this.productName = '',
    required this.isOnline,
    required this.imageUrl,
    this.badges = const [],
    this.isGridMode = false,
    this.onTap,
  });

  static const int kMaxNicknameLength = 16;

  static const Color _primaryPurple = Color(0xFF917CEE);
  static const Color _primaryLight = Color(0xFFF3F0FF);
  static const Color _bgPage = Color(0xFFF9F9FC);
  static const Color _pillGray = Color(0xFFF0EFF5);
  static const Color _onlineColor = Color(0xFF8CC152);
  static const Color _offlineColor = Color(0xFFF39191);
  static const Color _textMain = Color(0xFF333333);
  static const Color _textSub = Color(0xFF666666);
  static const Color _textMuted = Color(0xFF888888);

  String get _formattedName {
    final clean = deviceName.trim();
    if (clean.isEmpty) return 'FULLXPET';
    if (clean.characters.length <= kMaxNicknameLength) return clean;
    return '${clean.characters.take(kMaxNicknameLength)}…';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return isGridMode ? _buildGridCard(s) : _buildListCard(s);
  }

  /// 1. 单列卡片：主流大厂「左图 + 中间主副标题 + 右侧状态胶囊 + 底部动态数据」三段式布局
  Widget _buildListCard(S s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _pillGray, width: 1),
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
              // 上半层：左图（视觉锚点） + 中间名称与型号 + 右侧状态胶囊与箭头
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildNetworkImage(size: 60),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formattedName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textMain),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (productName.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            productName,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildStatusBadge(s),
                ],
              ),

              // 下半层：动态数据微摘要区（仅当该设备有 DP 数据时才显示）
              if (badges.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 10),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFF3F3F8), width: 1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: badges.map((b) => _buildDataBadge(b)).toList(),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFCCCCCC)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 2. 双列宫格卡片
  Widget _buildGridCard(S s) {
    final DeviceCardBadge? primaryBadge = badges.isNotEmpty ? badges.first : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _pillGray, width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF181828).withValues(alpha: 0.035),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_buildNetworkImage(size: 48), _buildStatusBadge(s, isCompact: true)],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formattedName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _textMain),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (productName.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    productName,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            if (primaryBadge != null) _buildDataBadge(primaryBadge) else const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  /// 右侧在线/离线状态胶囊
  Widget _buildStatusBadge(S s, {bool isCompact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 10, vertical: isCompact ? 3 : 4),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFFEFF8E6) : const Color(0xFFFFEFEF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: isOnline ? _onlineColor : _offlineColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            isOnline ? s.online : s.offline,
            style: TextStyle(
              fontSize: isCompact ? 10 : 11,
              fontWeight: FontWeight.bold,
              color: isOnline ? _onlineColor : _offlineColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 底部数据微摘要胶囊
  Widget _buildDataBadge(DeviceCardBadge badge) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: badge.isHighlight ? _primaryLight : _bgPage,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge.icon, size: 11, color: badge.isHighlight ? _primaryPurple : _textSub),
          const SizedBox(width: 4),
          Text(
            badge.text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: badge.isHighlight ? _primaryPurple : _textSub,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkImage({required double size}) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: _bgPage, borderRadius: BorderRadius.circular(16)),
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              width: size,
              height: size,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  decoration: BoxDecoration(color: const Color(0xFFECEAF6), borderRadius: BorderRadius.circular(12)),
                );
              },
              errorBuilder: (_, __, ___) => Icon(Icons.devices_other_rounded, size: size * 0.45, color: _primaryPurple),
            )
          : Icon(Icons.devices_other_rounded, size: size * 0.45, color: _primaryPurple),
    );
  }
}
