import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/widgets/app_avatar.dart';
import 'package:fullxpet/common/widgets/app_dialogs.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/widgets/responsive_layout.dart';
import 'package:fullxpet/features/user/providers/user_provider.dart';

class PersonalInfoPage extends StatelessWidget {
  const PersonalInfoPage({super.key});

  void _showEditNicknameDialog(BuildContext context, UserProvider provider, S s) {
    final TextEditingController controller = TextEditingController(text: provider.userName);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(s.editNickname, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: s.enterNewNickname,
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF917CEE))),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancel, style: const TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                FocusManager.instance.primaryFocus?.unfocus();
                final newName = controller.text.trim();
                Navigator.pop(ctx);
                if (newName.isNotEmpty && newName != provider.userName) {
                  final success = await provider.updateNickname(newName);
                  if (success && context.mounted) {
                    context.showAppToast(message: s.nicknameUpdated, type: AppToastType.success);
                  }
                }
              },
              child: Text(
                s.confirm,
                style: const TextStyle(color: Color(0xFF917CEE), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showImagePicker(BuildContext context, UserProvider provider, S s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(s.chooseFromGallery),
                onTap: () async {
                  Navigator.pop(ctx);
                  final success = await provider.uploadAvatar(ImageSource.gallery);
                  if (success && context.mounted) {
                    context.showAppToast(message: s.operationSuccess, type: AppToastType.success);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(s.takePhoto),
                onTap: () async {
                  Navigator.pop(ctx);
                  await provider.uploadAvatar(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 注销安全验证弹窗
  void _showDeleteAccountDialog(BuildContext context, UserProvider provider, S s) {
    final TextEditingController codeController = TextEditingController();
    int countdown = 0;
    Timer? timer;
    bool isSending = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            void startCountdown(int seconds) {
              setState(() => countdown = seconds);
              timer?.cancel();
              timer = Timer.periodic(const Duration(seconds: 1), (t) {
                if (countdown > 0) {
                  setState(() => countdown--);
                } else {
                  t.cancel();
                }
              });
            }

            return AlertDialog(
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
                    '注销后账号数据将永久删除且无法恢复。我们将向 ${provider.account} 发送验证码以确认操作。',
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
                            controller: codeController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: s.enterCode,
                              hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: (countdown > 0 || isSending)
                              ? null
                              : () async {
                                  setState(() => isSending = true);
                                  final cd = await provider.sendDeleteAccountCode();
                                  setState(() => isSending = false);
                                  if (cd > 0) {
                                    startCountdown(cd);
                                  } else if (provider.hasError && context.mounted) {
                                    context.showAppToast(message: provider.errorMsg, type: AppToastType.error);
                                  }
                                },
                          child: isSending
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF917CEE)),
                                )
                              : Text(
                                  countdown > 0 ? '${countdown}s' : s.sendCode,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: countdown > 0 ? Colors.grey : const Color(0xFF917CEE),
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
                  onPressed: () {
                    timer?.cancel();
                    Navigator.pop(ctx);
                  },
                  child: Text(s.cancel, style: const TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF37474),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    final code = codeController.text.trim();
                    if (code.isEmpty) {
                      context.showAppToast(message: s.enterCode, type: AppToastType.warning);
                      return;
                    }
                    FocusManager.instance.primaryFocus?.unfocus();
                    timer?.cancel();
                    Navigator.pop(ctx);

                    final success = await provider.deleteAccount(code);
                    if (!success && context.mounted) {
                      context.showAppToast(
                        message: provider.errorMsg.isNotEmpty ? provider.errorMsg : "注销失败",
                        type: AppToastType.error,
                      );
                    }
                  },
                  child: const Text(
                    "确认注销",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final provider = context.watch<UserProvider>();

    const Color textColor = Color(0xFF333333);
    const Color valueColor = Color(0xFF888888);
    const Color dividerColor = Color(0xFFEEEEEE);

    final String displayAccount = provider.account.isNotEmpty ? provider.account : s.notBound;

    String accountLabel = s.accountLabel;
    if (displayAccount.contains('@')) {
      accountLabel = s.emailLabel;
    } else if (RegExp(r'^\+?[0-9]+$').hasMatch(displayAccount)) {
      accountLabel = s.phoneLabel;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          s.personalInfo,
          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ResponsiveFormContainer(
          maxWidth: 500,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    // 1. 头像项
                    _buildListItem(
                      title: s.avatar,
                      textColor: textColor,
                      showArrow: true,
                      onTap: () => _showImagePicker(context, provider, s),
                      trailing: AppAvatar(avatarUrl: provider.avatarUrl, radius: 22),
                    ),
                    const Divider(height: 1, color: dividerColor),

                    // 2. 昵称项
                    _buildListItem(
                      title: s.nickname,
                      textColor: textColor,
                      trailingText: provider.userName,
                      valueColor: valueColor,
                      showArrow: true,
                      onTap: () => _showEditNicknameDialog(context, provider, s),
                    ),
                    const Divider(height: 1, color: dividerColor),

                    // 3. 真实账号展示
                    _buildListItem(
                      title: accountLabel,
                      textColor: textColor,
                      trailingText: displayAccount,
                      valueColor: valueColor,
                      showArrow: false,
                    ),
                    const Divider(height: 1, color: dividerColor),

                    const Spacer(),

                    // 4. 注销账号
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF37474),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                        ),
                        onPressed: () => _showDeleteAccountDialog(context, provider, s),
                        child: Text(
                          s.deleteAccount,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 5. 退出登录
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF917CEE),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          final bool? confirm = await context.showAppDialog(
                            title: s.logout,
                            content: '确定要退出当前账号吗？',
                            confirmText: s.confirm,
                            cancelText: s.cancel,
                          );
                          if (confirm == true) {
                            await provider.logout();
                          }
                        },
                        child: Text(
                          s.logout,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),

              if (provider.isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.2),
                  child: const Center(child: CircularProgressIndicator(color: Color(0xFF917CEE))),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem({
    required String title,
    Widget? trailing,
    String? trailingText,
    bool showArrow = false,
    required Color textColor,
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            if (trailing != null) trailing,
            if (trailingText != null)
              Expanded(
                child: Text(
                  trailingText,
                  style: TextStyle(fontSize: 15, color: valueColor),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (showArrow) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
            ],
          ],
        ),
      ),
    );
  }
}
