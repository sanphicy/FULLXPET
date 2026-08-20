import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/widgets/app_avatar.dart';
import 'package:fullxpet/common/widgets/responsive_layout.dart';
import 'package:fullxpet/features/user/viewmodels/user_view_model.dart';
import 'package:fullxpet/routes/app_router.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    const Color primaryPurple = Color(0xFF917CEE);
    const Color textColor = Color(0xFF333333);
    const Color subTextColor = Color(0xFF666666);
    const Color bgColor = Color(0xFFF9F9FC);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: ResponsiveFormContainer(
          maxWidth: 600,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // 1. 用户信息头部（局部监听 UserProvider）
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        Selector<UserProvider, String>(
                          selector: (_, vm) => vm.avatarUrl,
                          builder: (context, avatarUrl, _) =>
                              AppAvatar(avatarUrl: avatarUrl, radius: 32),
                        ),
                        Positioned(
                          bottom: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: primaryPurple,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              s.user,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
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
                          Selector<UserProvider, String>(
                            selector: (_, vm) => vm.userName,
                            builder: (context, userName, _) {
                              return Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          Selector<UserProvider, String>(
                            selector: (_, vm) => vm.userId,
                            builder: (context, userId, _) {
                              return Text(
                                'ID: $userId',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: subTextColor,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: subTextColor,
                        size: 24,
                      ),
                      onPressed: () {
                        context.push(AppRoutes.personalInfo);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // 2. 设置列表项 第一组
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildListTile(
                        Icons.privacy_tip_outlined,
                        const Color(0xFF917CEE),
                        s.privacyPolicy,
                        onTap: () {
                          context.push(
                            AppRoutes.webView,
                            extra: {
                              'title': s.privacyPolicy,
                              'url':
                                  'https://chen-2001.github.io/ljzn/FULLXPET_Privacy_Policy.html',
                            },
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildListTile(
                        Icons.description_outlined,
                        const Color(0xFFEE7C8C),
                        s.userAgreement,
                        onTap: () {
                          context.push(
                            AppRoutes.webView,
                            extra: {
                              'title': s.userAgreement,
                              'url':
                                  'https://chen-2001.github.io/ljzn/FULLXPET-User_Agreement.html',
                            },
                          );
                        },
                      ),
                      _buildDivider(),
                      Selector<UserProvider, String>(
                        selector: (_, vm) => vm.appVersion,
                        builder: (context, version, _) {
                          return _buildListTile(
                            Icons.info_outline,
                            const Color(0xFF5C7CEE),
                            s.appVersion,
                            trailingText: version,
                            onTap: () {},
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. 设置列表项 第二组
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildListTile(
                        Icons.lightbulb_outline,
                        const Color(0xFF3B9EBA),
                        s.feedback,
                        onTap: () => context.push(AppRoutes.feedback),
                      ),
                      _buildDivider(),
                      _buildListTile(
                        Icons.info_outline,
                        const Color(0xFF5C7CEE),
                        s.aboutUs,
                        onTap: () => context.push(AppRoutes.aboutUs),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(
    IconData icon,
    Color iconColor,
    String title, {
    String? trailingText,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF333333),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (trailingText != null && trailingText.isNotEmpty)
              Text(
                trailingText,
                style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
              ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 0.5,
      indent: 52,
      color: Color(0xFFF0EFF5),
    );
  }
}
