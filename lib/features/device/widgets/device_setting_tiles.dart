import 'package:flutter/material.dart';

typedef SettingWidgetList = List<Widget>;

/// 通用分组小标题积木
class DeviceSettingSectionTitle extends StatelessWidget {
  final String title;
  const DeviceSettingSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 18, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12, color: Color(0xFF888888), fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// 通用白底圆角卡片容器积木
class DeviceSettingCardGroup extends StatelessWidget {
  final SettingWidgetList children;
  const DeviceSettingCardGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }
}

/// 通用设置行积木
class DeviceSettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final Widget? trailingWidget;
  final bool showDivider;
  final bool showRedDot;
  final bool isLoading;
  final VoidCallback? onTap;

  const DeviceSettingTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.trailingWidget,
    this.showDivider = false,
    this.showRedDot = false,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 14, color: Color(0xFF333333), fontWeight: FontWeight.w600),
          ),
          subtitle: subtitle != null
              ? Text(subtitle!, style: const TextStyle(fontSize: 11, color: Color(0xFF999999)))
              : null,
          trailing:
              trailingWidget ??
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (trailingText != null)
                    Text(trailingText!, style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
                  if (isLoading) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF917CEE)),
                    ),
                  ] else if (showRedDot) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    ),
                  ],
                  const SizedBox(width: 5),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 13),
                ],
              ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          onTap: isLoading ? null : onTap,
        ),
        if (showDivider) const Divider(height: 1, thickness: 0.5, indent: 52, endIndent: 16, color: Color(0xFFF0EFF5)),
      ],
    );
  }
}
