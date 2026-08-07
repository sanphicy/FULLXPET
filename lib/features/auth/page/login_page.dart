import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/features/auth/auth_provider.dart';
import 'package:fullxpet/routes/app_router.dart';
import 'package:fullxpet/common/widgets/privacy_bottom_sheet.dart';
import 'package:flutter/gestures.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _accountCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  final ValueNotifier<bool> _isSubmitting = ValueNotifier(false);

  bool _agreedToTerms = false;
  bool _obscurePassword = true;

  final Color _primaryPurple = const Color(0xFF917CEE);
  final Color _inputBgColor = const Color(0xFFF0F0F0);
  final Color _textColor = const Color(0xFF333333);
  final Color _hintColor = const Color(0xFF9E9E9E);

  @override
  void dispose() {
    _accountCtrl.dispose();
    _passwordCtrl.dispose();
    _isSubmitting.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 36.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40.h),
              SizedBox(
                width: 90.w,
                height: 90.w,
                child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '欢迎使用 ',
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: _textColor),
                  ),
                  Text(
                    'FULLX PET',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40.h),
              Container(
                height: 52.h,
                decoration: BoxDecoration(color: _inputBgColor, borderRadius: BorderRadius.circular(26.r)),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  children: [
                    Icon(Icons.smartphone_outlined, color: _hintColor, size: 22.w),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: TextField(
                        controller: _accountCtrl,
                        style: TextStyle(color: _textColor, fontSize: 14.sp),
                        decoration: InputDecoration(
                          hintText: s.emailHint,
                          hintStyle: TextStyle(color: _hintColor, fontSize: 14.sp),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                height: 52.h,
                decoration: BoxDecoration(color: _inputBgColor, borderRadius: BorderRadius.circular(26.r)),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                      child: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: _hintColor,
                        size: 22.w,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: TextField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        style: TextStyle(color: _textColor, fontSize: 14.sp),
                        decoration: InputDecoration(
                          hintText: s.passwordHint,
                          hintStyle: TextStyle(color: _hintColor, fontSize: 14.sp),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.forgotPassword),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size(50.w, 30.h),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    s.forgotPassword,
                    style: TextStyle(color: _hintColor, fontSize: 13.sp),
                  ),
                ),
              ),
              SizedBox(height: 30.h),
              ValueListenableBuilder<bool>(
                valueListenable: _isSubmitting,
                builder: (context, isSubmitting, child) {
                  return SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              // 阻断：未勾选协议则弹出公共组件
                              if (!_agreedToTerms) {
                                final allowed = await PrivacyBottomSheet.show(context, _primaryPurple);
                                if (allowed) {
                                  setState(() => _agreedToTerms = true);
                                } else {
                                  return;
                                }
                              }

                              FocusManager.instance.primaryFocus?.unfocus();

                              final account = _accountCtrl.text.trim();
                              final password = _passwordCtrl.text.trim();

                              if (account.isEmpty || password.isEmpty) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(s.emptyAccountOrPassword)));
                                return;
                              }

                              final bool isEmail = RegExp(
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                              ).hasMatch(account);
                              final bool isPhone = RegExp(r'^1[3-9]\d{9}$').hasMatch(account);

                              if (!isEmail && !isPhone) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(s.invalidAccountFormat)));
                                return;
                              }

                              _isSubmitting.value = true;
                              final provider = context.read<LoginProvider>();

                              final success = await provider.login(account, password, isEmail: isEmail);

                              if (mounted) _isSubmitting.value = false;

                              if (success && mounted) {
                                this.context.go(AppRoutes.home);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.r)),
                        elevation: 0,
                      ),
                      child: isSubmitting
                          ? SizedBox(
                              width: 24.w,
                              height: 24.w,
                              child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              s.login,
                              style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
                            ),
                    ),
                  );
                },
              ),
              SizedBox(height: 16.h),
              TextButton(
                onPressed: () => context.push(AppRoutes.register),
                child: Text(
                  s.register,
                  style: TextStyle(color: _hintColor, fontSize: 14.sp),
                ),
              ),
              SizedBox(height: 60.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                    child: Container(
                      margin: EdgeInsets.only(right: 8.w),
                      width: 18.w,
                      height: 18.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _agreedToTerms ? _primaryPurple : _hintColor, width: 1.w),
                        color: _agreedToTerms ? _primaryPurple : Colors.transparent,
                      ),
                      child: _agreedToTerms ? Icon(Icons.check, size: 12.w, color: Colors.white) : null,
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: _hintColor, fontSize: 12.sp),
                      children: [
                        TextSpan(text: s.agreePrefix),
                        TextSpan(
                          text: s.userAgreement,
                          style: TextStyle(color: _primaryPurple),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              context.push(
                                AppRoutes.webView,
                                extra: {
                                  'title': s.userAgreement,
                                  'url': 'https://chen-2001.github.io/ljzn/FULLXPET-User_Agreement.html',
                                },
                              );
                            },
                        ),
                        TextSpan(text: s.andText),
                        TextSpan(
                          text: s.privacyPolicy,
                          style: TextStyle(color: _primaryPurple),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              context.push(
                                AppRoutes.webView,
                                extra: {
                                  'title': s.privacyPolicy,
                                  'url': 'https://chen-2001.github.io/ljzn/FULLXPET_Privacy_Policy.html',
                                },
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
