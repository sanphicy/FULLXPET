import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    final bool isPhoneMode = selectedIndex == 0;
    const Color hintColor = Color(0xFF9E9E9E);

    return Center(
      child: Container(
        height: 42.h,
        width: 280.w,
        decoration: BoxDecoration(color: const Color(0xFFF3F2F8), borderRadius: BorderRadius.circular(21.r)),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              alignment: isPhoneMode ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                width: 136.w,
                height: 38.h,
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(19.r),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTabChanged(0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.smartphone_outlined, size: 18.w, color: isPhoneMode ? primaryColor : hintColor),
                        SizedBox(width: 6.w),
                        Text(
                          '手机号',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: isPhoneMode ? FontWeight.bold : FontWeight.w500,
                            color: isPhoneMode ? primaryColor : hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTabChanged(1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.email_outlined, size: 18.w, color: !isPhoneMode ? primaryColor : hintColor),
                        SizedBox(width: 6.w),
                        Text(
                          '邮箱',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: !isPhoneMode ? FontWeight.bold : FontWeight.w500,
                            color: !isPhoneMode ? primaryColor : hintColor,
                          ),
                        ),
                      ],
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
