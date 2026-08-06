import 'package:flutter/material.dart';

class PasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final Color themeColor;
  final String hintText;

  const PasswordTextField({super.key, required this.controller, required this.themeColor, required this.hintText});

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final outlineColor = Theme.of(context).colorScheme.outline;

    return TextField(
      controller: widget.controller,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: Icon(Icons.lock_outline, color: widget.themeColor, size: 24),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: outlineColor, size: 24),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
    );
  }
}
