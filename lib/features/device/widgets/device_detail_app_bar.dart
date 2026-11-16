import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:fullxpet/common/widgets/app_dialogs.dart';
import 'package:fullxpet/routes/app_router.dart';

class DeviceDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String modelBadge; // 如 "V3", "V4", "AI"
  final String subtitle; // 如 "ID: 1032631000986"
  final VoidCallback? onSettingTap;

  const DeviceDetailAppBar({
    super.key,
    required this.title,
    this.modelBadge = '',
    required this.subtitle,
    this.onSettingTap,
  });

  static const Color _primaryPurple = Color(0xFF917CEE);
  static const Color _primaryLight = Color(0xFFF3F0FF);
  static const Color _textMain = Color(0xFF333333);
  static const Color _textMuted = Color(0xFF999999);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  String get _rawCopyId {
    return subtitle.replaceFirst(RegExp(r'^ID:\s*', caseSensitive: false), '').trim();
  }

  Future<void> _copyIdToClipboard(BuildContext context) async {
    final textToCopy = _rawCopyId;
    if (textToCopy.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: textToCopy));
    if (context.mounted) {
      context.showAppToast(message: '复制成功', type: AppToastType.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textMain, size: 18),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.home);
          }
        },
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  title.isNotEmpty ? title : 'FULLXPET',
                  style: const TextStyle(color: _textMain, fontSize: 15, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (modelBadge.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(color: _primaryLight, borderRadius: BorderRadius.circular(5)),
                  child: Text(
                    modelBadge,
                    style: const TextStyle(color: _primaryPurple, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          // 点击副标题或右侧复制小图标，一键复制纯设备 ID
          if (subtitle.isNotEmpty)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _copyIdToClipboard(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        subtitle,
                        style: const TextStyle(color: _textMuted, fontSize: 11, fontFamily: 'monospace'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.copy_rounded, size: 11, color: _primaryPurple),
                  ],
                ),
              ),
            ),
        ],
      ),
      actions: [
        if (onSettingTap != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.more_vert_rounded, color: _primaryPurple, size: 20),
              ),
              onPressed: onSettingTap,
            ),
          ),
      ],
    );
  }
}
