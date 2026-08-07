import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PrivacyBottomSheet {
  /// 弹出全局统一的隐私合规确认底窗
  static Future<bool> show(BuildContext context, Color primaryColor) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      isDismissible: false, // 强制用户必须点击按钮做出选择
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '服务协议与隐私政策',
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
                ),
                SizedBox(height: 16.h),
                // 补全授权提示语句，明确告知用户点击的后果
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 13.sp, color: const Color(0xFF666666), height: 1.6),
                    children: const [
                      TextSpan(text: '感谢您使用 FULLX PET！在您使用本应用前，请认真阅读并了解《用户协议》与《隐私政策》。我们非常重视您的个人信息和隐私保护。\n\n'),
                      TextSpan(
                        text: '点击“同意并继续”即表示您已阅读并同意上述全部协议。',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333333)), // 稍微加深强调
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30.h),
                Row(
                  children: [
                    // 左侧弱化按钮：不同意
                    Expanded(
                      child: SizedBox(
                        height: 48.h,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: const Color(0xFF999999), width: 1.w),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
                          ),
                          child: Text(
                            '不同意',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: const Color(0xFF666666),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    // 右侧强调按钮：同意并继续
                    Expanded(
                      child: SizedBox(
                        height: 48.h,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
                          ),
                          child: Text(
                            '同意并继续',
                            style: TextStyle(fontSize: 16.sp, color: Colors.white, fontWeight: FontWeight.bold),
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
      },
    );
    return result ?? false;
  }
}
