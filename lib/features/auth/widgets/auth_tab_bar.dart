import 'package:flutter/material.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';

class AuthTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final Color primaryColor;

  const AuthTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
    this.primaryColor = const Color(0xFF917CEE),
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final bool isPhoneMode = selectedIndex == 0;
    const Color hintColor = Color(0xFF9E9E9E);

    return Center(
      child: Container(
        height: 44,
        width: 280,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: const Color(0xFFF3F2F8), borderRadius: BorderRadius.circular(22)),
        child: Stack(
          children: [
            // 动画白色滑块：严格占 50% 宽度，左右平滑滑动
            AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOutCubic,
              alignment: isPhoneMode ? Alignment.centerLeft : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(19),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                ),
              ),
            ),
            // 文字与图标区域：严格等分
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTabChanged(0),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.smartphone_outlined, size: 18, color: isPhoneMode ? primaryColor : hintColor),
                          const SizedBox(width: 6),
                          Text(
                            s.phoneLogin,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isPhoneMode ? FontWeight.bold : FontWeight.w500,
                              color: isPhoneMode ? primaryColor : hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTabChanged(1),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.email_outlined, size: 18, color: !isPhoneMode ? primaryColor : hintColor),
                          const SizedBox(width: 6),
                          Text(
                            s.emailLogin,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: !isPhoneMode ? FontWeight.bold : FontWeight.w500,
                              color: !isPhoneMode ? primaryColor : hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
