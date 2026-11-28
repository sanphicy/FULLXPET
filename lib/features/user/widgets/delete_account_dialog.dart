import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/theme/app_theme.dart';
import 'package:fullxpet/common/widgets/app_dialogs.dart';
import 'package:fullxpet/features/user/viewmodels/user_view_model.dart';

class DeleteAccountDialog extends StatefulWidget {
  final UserViewModel vm;
  final String account;

  const DeleteAccountDialog({super.key, required this.vm, required this.account});

  static Future<void> show(BuildContext context, {required UserViewModel vm, required String account}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeleteAccountDialog(vm: vm, account: account),
    );
  }

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final TextEditingController _codeController = TextEditingController();
  Timer? _timer;
  int _countdown = 0;
  bool _isSending = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    setState(() => _countdown = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        t.cancel();
        setState(() => _countdown = 0);
      }
    });
  }

  Future<void> _handleSendCode() async {
    setState(() => _isSending = true);
    final cd = await widget.vm.sendDeleteAccountCode();
    if (!mounted) return;
    setState(() => _isSending = false);

    if (cd > 0) {
      _startCountdown(cd);
    }
  }

  Future<void> _handleSubmit(S s) async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      context.showAppToast(message: s.enterCode, type: AppToastType.warning);
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isSubmitting = true);
    final ok = await widget.vm.deleteAccount(code);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      _timer?.cancel();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return PopScope(
      canPop: !_isSubmitting,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFF37474), size: 24),
            const SizedBox(width: 8),
            Text(s.deleteAccount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '注销后账号数据将永久删除且无法恢复。我们将向 ${widget.account} 发送验证码以确认操作。',
              style: const TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      enabled: !_isSubmitting,
                      decoration: InputDecoration(
                        hintText: s.enterCode,
                        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: (_countdown > 0 || _isSending || _isSubmitting) ? null : _handleSendCode,
                    child: _isSending
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryPurple),
                          )
                        : Text(
                            _countdown > 0 ? '${_countdown}s' : s.sendCode,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _countdown > 0 ? Colors.grey : AppTheme.primaryPurple,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            child: Text(s.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF37474),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _isSubmitting ? null : () => _handleSubmit(s),
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    '确认注销',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}
