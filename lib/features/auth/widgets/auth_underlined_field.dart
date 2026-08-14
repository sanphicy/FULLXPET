import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthUnderlinedField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? icon;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final TextInputType keyboardType;
  final Widget? trailing;

  const AuthUnderlinedField({
    super.key,
    required this.controller,
    required this.hintText,
    this.icon,
    this.isPassword = false,
    this.obscureText = false,
    this.onToggleObscure,
    this.keyboardType = TextInputType.text,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    const Color textColor = Color(0xFF333333);
    const Color hintColor = Color(0xFF9E9E9E);
    const Color lineColor = Color(0xFFE5E5E5);

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: lineColor, width: 1)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, color: textColor, size: 20.w), SizedBox(width: 8.w)],
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: isPassword ? obscureText : false,
              style: TextStyle(color: textColor, fontSize: 15.sp),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: hintColor, fontSize: 14.sp),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14.h),
              ),
            ),
          ),
          if (isPassword)
            GestureDetector(
              onTap: onToggleObscure,
              child: Icon(
                obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: hintColor,
                size: 20.w,
              ),
            ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
