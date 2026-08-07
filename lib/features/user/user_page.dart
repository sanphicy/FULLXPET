import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/features/user/user_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fullxpet/routes/app_router.dart';
import 'package:fullxpet/common/widgets/app_avatar.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    const Color primaryPurple = Color(0xFF917CEE);
    const Color textColor = Color(0xFF333333);
    const Color subTextColor = Color(0xFF666666);
    const Color bgColor = Color(0xFFF9F9FC);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // ==============================
              // 1. 用户信息头部
              // ==============================
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      AppAvatar(avatarUrl: provider.avatarUrl, radius: 32),
                      Positioned(
                        bottom: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: primaryPurple, borderRadius: BorderRadius.circular(10)),
                          child: const Text(
                            'User',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              provider.userName,
                              style: const TextStyle(fontSize: 18, color: textColor, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('ID: ${provider.userId}', style: TextStyle(fontSize: 12, color: subTextColor)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: subTextColor, size: 24),
                    onPressed: () {
                      context.push(AppRoutes.personalInfo, extra: provider);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // ==============================
              // 2. 设置列表项 第一组
              // ==============================
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    // _buildListTile(Icons.language_outlined, const Color(0xFF7C8CEE), '语言设置'),
                    // _buildDivider(),
                    _buildListTile(
                      Icons.privacy_tip_outlined,
                      const Color(0xFF917CEE),
                      '隐私政策',
                      onTap: () {
                        context.push(
                          AppRoutes.webView,
                          extra: {
                            'title': '隐私政策',
                            'url': 'https://chen-2001.github.io/ljzn/FULLXPET_Privacy_Policy.html',
                          },
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildListTile(
                      Icons.description_outlined,
                      const Color(0xFFEE7C8C),
                      '用户协议',
                      onTap: () {
                        context.push(
                          AppRoutes.webView,
                          extra: {
                            'title': '用户协议',
                            'url': 'https://chen-2001.github.io/ljzn/FULLXPET-User_Agreement.html',
                          },
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildListTile(
                      Icons.info_outline,
                      const Color(0xFF5C7CEE),
                      '软件版本',
                      trailingText: provider.appVersion,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ==============================
              // 3. 设置列表项 第二组
              // ==============================
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    _buildListTile(
                      Icons.lightbulb_outline,
                      const Color(0xFF3B9EBA),
                      '意见反馈',
                      onTap: () {
                        context.push(AppRoutes.feedback);
                      },
                    ),
                    _buildDivider(),
                    _buildListTile(
                      Icons.info_outline,
                      const Color(0xFF5C7CEE),
                      '关于我们',
                      onTap: () {
                        context.push(AppRoutes.aboutUs);
                      },
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, Color iconColor, String title, {String? trailingText, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Color(0xFF333333), fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            if (trailingText != null && trailingText.isNotEmpty)
              Text(trailingText, style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 0.5, indent: 52, color: Color(0xFFF0EFF5));
  }
}
