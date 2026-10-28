import 'package:flutter/material.dart';

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
      height: 54,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: lineColor, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            SizedBox(
              width: 24,
              height: 24,
              child: Center(child: Icon(icon, color: textColor, size: 20)),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: isPassword ? obscureText : false,
              style: const TextStyle(color: textColor, fontSize: 15),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: hintColor, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (isPassword)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggleObscure,
              child: SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: Icon(
                    obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: hintColor,
                    size: 20,
                  ),
                ),
              ),
            ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
