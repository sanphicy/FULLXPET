import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/providers/user_provider.dart';
import 'package:fullxpet/common/widgets/app_avatar.dart';
import 'package:fullxpet/common/widgets/responsive_layout.dart';
import 'package:fullxpet/features/device/device_list/device_card.dart';
import 'package:fullxpet/features/device/device_provider.dart';
import 'package:fullxpet/features/device/models/device_item_dto.dart';
import 'package:fullxpet/routes/app_router.dart';

class DeviceListPage extends StatefulWidget {
  const DeviceListPage({super.key});

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  static const Color _primaryPurple = Color(0xFF917CEE);
  static const Color _primaryLight = Color(0xFFF3F0FF);
  static const Color _bgPage = Color(0xFFF9F9FC);
  static const Color _pillGray = Color(0xFFF0EFF5);
  static const Color _onlineColor = Color(0xFF8CC152);
  static const Color _textMain = Color(0xFF333333);
  static const Color _textSub = Color(0xFF666666);
  static const Color _textMuted = Color(0xFF999999);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceProvider>().fetchDevices();
      context.read<UserProvider>().fetchUserInfo(isSilent: true);
    });
  }

  /// 多 Tab (>4) 时的底部全部分类抽屉
  void _openCategoryDrawer(BuildContext context, DeviceProvider provider, FilterTabList tabs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '快速筛选设备分类',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _textMain),
                        ),
                        SizedBox(height: 2),
                        Text('选择下方类目直达对应设备', style: TextStyle(fontSize: 11, color: _textMuted)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: _textSub),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tabs.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.55,
                  ),
                  itemBuilder: (context, index) {
                    final tab = tabs[index];
                    final isSelected = provider.selectedCategoryKey == tab.key;
                    return GestureDetector(
                      onTap: () {
                        provider.selectCategory(tab.key);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected ? _primaryLight : _bgPage,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? _primaryPurple : Colors.transparent, width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  tab.key == 'ALL' ? Icons.grid_view_rounded : Icons.pets_rounded,
                                  size: 15,
                                  color: isSelected ? _primaryPurple : _textSub,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${tab.count}台',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? _primaryPurple : _textSub,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              tab.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? _primaryPurple : _textMain,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context, S s) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: const Color(0xFFF4F5F0),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    s.useGuide,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 16),
                _buildGuideItem(s.guideStep1),
                _buildGuideItem(s.guideStep2),
                _buildGuideItem(s.guideStep3),
                _buildGuideItem(s.guideStep4),
                const SizedBox(height: 24),
                Center(
                  child: SizedBox(
                    width: 140,
                    height: 40,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF999999), width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        s.iUnderstand,
                        style: const TextStyle(fontSize: 14, color: _textMain, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuideItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 13, color: _textSub, height: 1.4)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final provider = context.watch<DeviceProvider>();
    final categoryTabs = provider.categoryTabs;
    final subProductTabs = provider.subProductTabs;
    final filteredDevices = provider.filteredDevices;

    return Scaffold(
      backgroundColor: _bgPage,
      body: SafeArea(
        child: ResponsiveFormContainer(
          maxWidth: 600,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 顶部 Header（无头像绿点）
                _buildTopHeader(context, s, provider),
                const SizedBox(height: 14),

                // 2. 动态分类筛选区
                if (categoryTabs.isNotEmpty) ...[
                  Text(
                    s.myDevices,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _textMain),
                  ),
                  const SizedBox(height: 10),
                  _buildAdaptiveCategoryBar(context, provider, categoryTabs),
                  if (subProductTabs.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildSubProductBar(provider, subProductTabs),
                  ],
                  const SizedBox(height: 14),
                ],

                // 3. 设备列表 / 双列宫格
                Expanded(
                  child: RefreshIndicator(
                    color: _primaryPurple,
                    backgroundColor: Colors.white,
                    onRefresh: () => provider.fetchDevices(),
                    child: provider.isLoading && filteredDevices.isEmpty
                        ? const Center(child: CircularProgressIndicator(color: _primaryPurple))
                        : filteredDevices.isEmpty
                        ? _buildEmptyState(context, s)
                        : provider.isGridView
                        ? GridView.builder(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            itemCount: filteredDevices.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.05,
                            ),
                            itemBuilder: (context, index) =>
                                _buildCardItem(context, provider, filteredDevices[index], isGrid: true),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            itemCount: filteredDevices.length,
                            itemBuilder: (context, index) =>
                                _buildCardItem(context, provider, filteredDevices[index], isGrid: false),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, S s, DeviceProvider provider) {
    return Selector<UserProvider, (String, String)>(
      selector: (_, userVm) => (userVm.user.avatarUrl, userVm.user.nickname),
      builder: (context, userData, _) {
        final avatarUrl = userData.$1;
        final rawName = userData.$2.trim();
        final userName = (rawName.isNotEmpty && rawName != 'Unknown User') ? rawName : 'User';

        return Row(
          children: [
            // 纯净头像，已移除右下角绿点
            AppAvatar(avatarUrl: avatarUrl, radius: 21),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $userName',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textMain),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: _onlineColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${s.online}: ${provider.onlineCount}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textSub),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text('|', style: TextStyle(fontSize: 10, color: Color(0xFFDDDDDD))),
                      ),
                      Text(
                        '${s.offline}: ${provider.offlineCount}',
                        style: const TextStyle(fontSize: 11, color: _textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildCircleIconButton(
              icon: provider.isGridView ? Icons.view_agenda_outlined : Icons.grid_view_rounded,
              color: _textSub,
              bgColor: Colors.white,
              onTap: () => provider.toggleLayoutMode(),
            ),
            const SizedBox(width: 6),
            _buildCircleIconButton(
              icon: Icons.help_outline_rounded,
              color: _textSub,
              bgColor: Colors.white,
              onTap: () => _showHelpDialog(context, s),
            ),
            const SizedBox(width: 6),
            _buildCircleIconButton(
              icon: Icons.add_rounded,
              color: Colors.white,
              bgColor: _primaryPurple,
              onTap: () => context.push(AppRoutes.deviceAddSearch),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildAdaptiveCategoryBar(BuildContext context, DeviceProvider provider, FilterTabList tabs) {
    final bool isFewTabs = tabs.length <= 4;

    if (isFewTabs) {
      return Row(
        children: [
          for (int i = 0; i < tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _buildChipPill(
                tab: tabs[i],
                isSelected: provider.selectedCategoryKey == tabs[i].key,
                onTap: () => provider.selectCategory(tabs[i].key),
              ),
            ),
          ],
        ],
      );
    }

    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final tab = tabs[index];
                return _buildChipPill(
                  tab: tab,
                  isSelected: provider.selectedCategoryKey == tab.key,
                  onTap: () => provider.selectCategory(tab.key),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _openCategoryDrawer(context, provider, tabs),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E5EC)),
              ),
              child: const Icon(Icons.tune_rounded, size: 16, color: _primaryPurple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubProductBar(DeviceProvider provider, FilterTabList subTabs) {
    return SizedBox(
      height: 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: subTabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final sub = subTabs[index];
          final isSelected = provider.selectedProductId == sub.key;
          return GestureDetector(
            onTap: () => provider.selectSubProduct(sub.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? _primaryLight : _pillGray,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isSelected ? _primaryPurple : Colors.transparent, width: 1),
              ),
              child: Text(
                '${sub.label} (${sub.count})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? _primaryPurple : _textSub,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChipPill({required DeviceFilterTab tab, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? _primaryPurple : Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: isSelected ? _primaryPurple : const Color(0xFFE5E5EC), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                tab.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : _textSub,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.22) : _pillGray,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${tab.count}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : _textSub,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardItem(BuildContext context, DeviceProvider provider, DeviceItemDto item, {required bool isGrid}) {
    return DeviceCard(
      deviceName: item.nickname,
      productName: provider.resolveProductName(item),
      isOnline: item.online,
      imageUrl: provider.resolveImageUrl(item),
      badges: provider.resolveDeviceBadges(item),
      isGridMode: isGrid,
      onTap: () => context.push(AppRoutes.deviceManagerPath(item.deviceId)),
    );
  }

  Widget _buildEmptyState(BuildContext context, S s) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      children: [
        const SizedBox(height: 110),
        Icon(Icons.pets_rounded, size: 72, color: Colors.grey.shade300),
        const SizedBox(height: 14),
        const Center(
          child: Text('暂未绑定智能设备，点击右上角 "+" 添加', style: TextStyle(fontSize: 13, color: _textMuted)),
        ),
      ],
    );
  }
}
