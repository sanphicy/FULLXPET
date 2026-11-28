import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/models/user_dto.dart';
import 'package:fullxpet/common/providers/user_provider.dart';
import 'package:fullxpet/common/theme/app_theme.dart';
import 'package:fullxpet/common/widgets/app_avatar.dart';
import 'package:fullxpet/common/widgets/app_dialogs.dart';
import 'package:fullxpet/common/widgets/responsive_layout.dart';
import 'package:fullxpet/features/user/viewmodels/user_view_model.dart';
import 'package:fullxpet/features/user/widgets/delete_account_dialog.dart';
import 'package:fullxpet/features/user/widgets/edit_nickname_dialog.dart';

class PersonalInfoPage extends StatelessWidget {
  const PersonalInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(create: (_) => UserViewModel(), child: const _PersonalInfoView());
  }
}

class _PersonalInfoView extends StatelessWidget {
  const _PersonalInfoView();

  Future<void> _handleEditNickname(BuildContext context, UserViewModel vm, String currentNickname, S s) async {
    final newName = await EditNicknameDialog.show(context, initialNickname: currentNickname);
    if (!context.mounted || newName == null || newName.isEmpty || newName == currentNickname) return;

    final success = await vm.updateNickname(newName);
    if (success && context.mounted) {
      context.showAppToast(message: s.nicknameUpdated, type: AppToastType.success);
    }
  }

  Future<void> _handleUploadAvatar(BuildContext context, UserViewModel vm, ImageSource source, S s) async {
    final success = await vm.uploadAvatar(source);
    if (success && context.mounted) {
      context.showAppToast(message: s.operationSuccess, type: AppToastType.success);
    }
  }

  void _showImagePicker(BuildContext context, UserViewModel vm, S s) {
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
                onTap: () {
                  Navigator.pop(ctx);
                  _handleUploadAvatar(context, vm, ImageSource.gallery, s);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(s.takePhoto),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleUploadAvatar(context, vm, ImageSource.camera, s);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleDeleteAccount(BuildContext context, UserViewModel vm, String account) {
    if (account.isEmpty) {
      context.showAppToast(message: '未获取到当前账号', type: AppToastType.warning);
      return;
    }
    DeleteAccountDialog.show(context, vm: vm, account: account);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final vm = context.watch<UserViewModel>();
    final user = context.select<UserProvider, UserDto>((p) => p.user);

    const Color textColor = Color(0xFF333333);
    const Color valueColor = Color(0xFF888888);
    const Color dividerColor = Color(0xFFEEEEEE);

    final String displayAccount = user.account.isNotEmpty ? user.account : s.notBound;

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
                    // 1. 头像
                    _buildListItem(
                      title: s.avatar,
                      textColor: textColor,
                      showArrow: true,
                      onTap: () => _showImagePicker(context, vm, s),
                      trailing: AppAvatar(avatarUrl: user.avatarUrl, radius: 22),
                    ),
                    const Divider(height: 1, color: dividerColor),

                    // 2. 昵称
                    _buildListItem(
                      title: s.nickname,
                      textColor: textColor,
                      trailingText: user.nickname,
                      valueColor: valueColor,
                      showArrow: true,
                      onTap: () => _handleEditNickname(context, vm, user.nickname, s),
                    ),
                    const Divider(height: 1, color: dividerColor),

                    // 3. 账号
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
                        onPressed: () => _handleDeleteAccount(context, vm, user.account),
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
                          backgroundColor: AppTheme.primaryPurple,
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
                          if (confirm == true && context.mounted) {
                            await context.read<UserProvider>().logout();
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

              if (vm.isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.2),
                  child: const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple)),
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
