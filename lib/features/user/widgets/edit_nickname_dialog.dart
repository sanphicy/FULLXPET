import 'package:flutter/material.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/theme/app_theme.dart';

class EditNicknameDialog extends StatefulWidget {
  final String initialNickname;

  const EditNicknameDialog({super.key, required this.initialNickname});

  static Future<String?> show(BuildContext context, {required String initialNickname}) {
    return showDialog<String>(
      context: context,
      builder: (_) => EditNicknameDialog(initialNickname: initialNickname),
    );
  }

  @override
  State<EditNicknameDialog> createState() => _EditNicknameDialogState();
}

class _EditNicknameDialogState extends State<EditNicknameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNickname);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(s.editNickname, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: s.enterNewNickname,
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryPurple)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel, style: const TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.pop(context, _controller.text.trim());
          },
          child: Text(
            s.confirm,
            style: const TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
