import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:fullxpet/routes/app_router.dart';

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
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 13.sp, color: const Color(0xFF666666), height: 1.6),
                    children: [
                      const TextSpan(text: '欢迎来到 FULLX PET！\n\n在使用我们的服务前，请仔细阅读并同意'),
                      TextSpan(
                        text: '《用户协议》',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            context.push(
                              AppRoutes.webView,
                              extra: {
                                'title': '用户协议',
                                'url': 'https://chen-2001.github.io/ljzn/FULLXPET-User_Agreement.html',
                              },
                            );
                          },
                      ),
                      const TextSpan(text: '和'),
                      TextSpan(
                        text: '《隐私政策》',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            context.push(
                              AppRoutes.webView,
                              extra: {
                                'title': '隐私政策',
                                'url': 'https://chen-2001.github.io/ljzn/FULLXPET_Privacy_Policy.html',
                              },
                            );
                          },
                      ),
                      const TextSpan(text: '。我们将严格保护您的个人信息安全。'),
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
