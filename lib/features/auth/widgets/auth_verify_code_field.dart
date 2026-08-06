import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fullxpet/common/constants/dimens.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';

class AuthVerifyCodeField extends StatefulWidget {
  final Future<bool> Function() onSendCode;
  final TextEditingController? controller;

  const AuthVerifyCodeField({super.key, required this.onSendCode, this.controller});

  @override
  State<AuthVerifyCodeField> createState() => _AuthVerifyCodeFieldState();
}

class _AuthVerifyCodeFieldState extends State<AuthVerifyCodeField> {
  bool _isSending = false;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _handleSend() async {
    if (_isSending || _countdown > 0) return;
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() => _isSending = true);
    final success = await widget.onSendCode();

    if (mounted) {
      setState(() => _isSending = false);
      if (success) {
        _startCountdown();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    return Row(
      children: [
        Container(
          height: Dimens.buttonLarge,
          width: 100.w,
          decoration: BoxDecoration(
            color: _countdown > 0 ? const Color(0xFFF2F2F2) : Colors.white,
            borderRadius: BorderRadius.circular(Dimens.radiusLarge),
            border: Border.all(color: _countdown > 0 ? Colors.transparent : Colors.black12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(Dimens.radiusLarge),
              onTap: (_countdown > 0 || _isSending) ? null : _handleSend,
              child: Center(
                child: _isSending
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(color: Colors.black87, strokeWidth: 2),
                      )
                    : Text(
                        _countdown > 0 ? '${_countdown}s' : s.sendCode,
                        style: TextStyle(
                          color: _countdown > 0 ? Colors.black38 : Colors.black87,
                          fontSize: Dimens.fontNormal,
                        ),
                      ),
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Container(
            height: Dimens.buttonLarge,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(Dimens.radiusLarge),
            ),
            padding: EdgeInsets.symmetric(horizontal: Dimens.screenPadding),
            child: TextField(
              controller: widget.controller,
              decoration: InputDecoration(
                hintText: s.enterCode,
                hintStyle: TextStyle(color: Colors.black38, fontSize: Dimens.fontNormal),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
