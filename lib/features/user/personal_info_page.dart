import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/widgets/app_avatar.dart';
import 'package:fullxpet/features/user/user_provider.dart';

class PersonalInfoPage extends StatelessWidget {
  const PersonalInfoPage({super.key});

  /// 显示修改昵称的弹窗
  void _showEditNicknameDialog(BuildContext context, UserProvider provider) {
    final TextEditingController controller = TextEditingController(text: provider.userName);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('修改昵称', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '请输入新昵称',
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF917CEE))),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                FocusManager.instance.primaryFocus?.unfocus();
                final newName = controller.text.trim();
                Navigator.pop(ctx);
                if (newName.isNotEmpty && newName != provider.userName) {
                  await provider.updateNickname(newName);
                }
              },
              child: const Text(
                '确认',
                style: TextStyle(color: Color(0xFF917CEE), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 显示选择头像的来源
  void _showImagePicker(BuildContext context, UserProvider provider) {
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
                title: const Text('从相册选择'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await provider.uploadAvatar(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('拍照'),
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();

    const Color textColor = Color(0xFF333333);
    const Color valueColor = Color(0xFF888888);
    const Color dividerColor = Color(0xFFEEEEEE);

    // 获取实际可见账号，去除 ID 兜底
    final String displayAccount = provider.account.isNotEmpty ? provider.account : '未绑定';

    // 智能判断显示标签
    String accountLabel = '账号';
    if (displayAccount.contains('@')) {
      accountLabel = '邮箱';
    } else if (RegExp(r'^\+?[0-9]+$').hasMatch(displayAccount)) {
      accountLabel = '手机号';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '个人信息',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                // 1. 头像项
                _buildListItem(
                  title: '头像',
                  textColor: textColor,
                  showArrow: true,
                  onTap: () => _showImagePicker(context, provider),
                  trailing: AppAvatar(avatarUrl: provider.avatarUrl, radius: 22),
                ),
                const Divider(height: 1, color: dividerColor),

                // 2. 昵称项
                _buildListItem(
                  title: '昵称',
                  textColor: textColor,
                  trailingText: provider.userName,
                  valueColor: valueColor,
                  showArrow: true,
                  onTap: () => _showEditNicknameDialog(context, provider),
                ),
                const Divider(height: 1, color: dividerColor),

                // 3. 真实账号展示（智能判断标题，不使用 ID）
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
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF37474),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      // TODO: 接入注销账号 API
                    },
                    child: const Text(
                      '注销账号',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // 5. 退出登录
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF917CEE),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () => provider.logout(),
                    child: const Text(
                      '退出登录',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),

          // 全局 Loading
          if (provider.isLoading)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: const Center(child: CircularProgressIndicator(color: Color(0xFF917CEE))),
            ),
        ],
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
            if (trailingText != null) Text(trailingText, style: TextStyle(fontSize: 15, color: valueColor)),
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
