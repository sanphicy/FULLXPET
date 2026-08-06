import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fullxpet/common/constants/dimens.dart';

class AuthTextField extends StatefulWidget {
  final String hintText;
  final bool isPassword;
  final TextEditingController? controller;

  const AuthTextField({super.key, required this.hintText, this.isPassword = false, this.controller});

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Dimens.buttonLarge,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(Dimens.radiusLarge),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              obscureText: _obscureText,
              style: const TextStyle(color: Color(0xFF333333)),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(color: const Color(0xFF9E9E9E), fontSize: Dimens.fontNormal), // 14.sp
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (widget.isPassword)
            GestureDetector(
              onTap: () => setState(() => _obscureText = !_obscureText),
              child: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF333333),
                size: Dimens.iconNormal,
              ),
            ),
        ],
      ),
    );
  }
}
