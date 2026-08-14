import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/widgets/privacy_bottom_sheet.dart';
import 'package:fullxpet/features/auth/viewmodels/login_view_model.dart';
import 'package:fullxpet/features/auth/widgets/country_picker_sheet.dart';
import 'package:fullxpet/routes/app_router.dart';

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
  final Color _lineColor = const Color(0xFFE5E5E5);

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
    final viewModel = context.watch<LoginViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // 顶部国家/地区快速切换入口
          GestureDetector(
            onTap: () async {
              final country = await CountryPickerSheet.show(context);
              if (country != null && mounted) {
                viewModel.switchCountry(country);
              }
            },
            child: Container(
              margin: EdgeInsets.only(right: 20.w),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(color: const Color(0xFFF3F2F8), borderRadius: BorderRadius.circular(12.r)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    viewModel.currentCountry?.name ?? "国家/地区",
                    style: TextStyle(fontSize: 12.sp, color: _primaryPurple, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.arrow_drop_down, color: _primaryPurple, size: 18.w),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 36.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20.h),
              SizedBox(
                width: 90.w,
                height: 90.w,
                child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
              ),
              SizedBox(height: 20.h),
              Text(
                'FULLX PET',
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: _textColor, letterSpacing: 1.1),
              ),
              SizedBox(height: 35.h),

              // 账号输入框
              Container(
                height: 52.h,
                decoration: BoxDecoration(color: _inputBgColor, borderRadius: BorderRadius.circular(26.r)),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: _hintColor, size: 22.w),
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

              // 密码输入框
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
              SizedBox(height: 25.h),

              // 登录按钮
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

                              _isSubmitting.value = true;
                              final success = await viewModel.login(account, password, isEmail: isEmail);
                              if (mounted) _isSubmitting.value = false;

                              if (success && mounted) {
                                context.go(AppRoutes.home);
                              } else if (viewModel.hasError && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(viewModel.errorMsg)));
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
              SizedBox(height: 50.h),

              // 协议勾选
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
