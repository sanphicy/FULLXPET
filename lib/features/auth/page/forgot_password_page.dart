import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/features/auth/viewmodels/forgot_password_view_model.dart';
import 'package:fullxpet/features/auth/widgets/auth_tab_bar.dart';
import 'package:fullxpet/features/auth/widgets/auth_underlined_field.dart';
import 'package:fullxpet/features/auth/widgets/country_picker_sheet.dart';
import 'package:fullxpet/routes/app_router.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  int _tabIndex = 0;
  final TextEditingController _accountCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();
  final ValueNotifier<bool> _isSubmitting = ValueNotifier(false);
  final ValueNotifier<bool> _isSendingCode = ValueNotifier(false);
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _countdown = 0;

  final Color _primaryPurple = const Color(0xFF917CEE);
  final Color _textColor = const Color(0xFF333333);
  final Color _hintColor = const Color(0xFF9E9E9E);
  final Color _lineColor = const Color(0xFFE5E5E5);

  @override
  void dispose() {
    _accountCtrl.dispose();
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _isSubmitting.dispose();
    _isSendingCode.dispose();
    super.dispose();
  }

  void _startCountdown(int seconds) {
    setState(() => _countdown = seconds);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_countdown > 0) {
        setState(() => _countdown--);
        return true;
      }
      return false;
    });
  }

  Future<void> _handleResetPassword(ForgotPasswordViewModel viewModel, S s) async {
    final account = _accountCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    final pwd = _passwordCtrl.text.trim();
    final confirmPwd = _confirmPasswordCtrl.text.trim();

    if (account.isEmpty || code.isEmpty || pwd.isEmpty || confirmPwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写完整信息')));
      return;
    }

    final isPhoneMode = _tabIndex == 0;
    if (isPhoneMode) {
      final bool isPhone = RegExp(r'^\d{5,15}$').hasMatch(account);
      if (!isPhone) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('手机号格式不正确')));
        return;
      }
    } else {
      final bool isEmail = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(account);
      if (!isEmail) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('邮箱格式不正确')));
        return;
      }
    }

    if (pwd != confirmPwd) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('两次输入的密码不一致')));
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    _isSubmitting.value = true;

    final success = await viewModel.resetPassword(
      account: account,
      newPassword: pwd,
      code: code,
      isPhoneMode: isPhoneMode,
    );

    if (mounted) _isSubmitting.value = false;
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('密码重置成功，请重新登录')));
      context.go(AppRoutes.login);
    } else if (viewModel.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(viewModel.errorMsg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final viewModel = context.watch<ForgotPasswordViewModel>();
    final isPhoneMode = _tabIndex == 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: _textColor, size: 22.w),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          GestureDetector(
            onTap: () => CountryPickerSheet.show(context),
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
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10.h),
              Center(
                child: SizedBox(
                  width: 80.w,
                  height: 80.w,
                  child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                '找回密码',
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: _textColor),
              ),
              SizedBox(height: 25.h),

              // 复用抽取的 Tab 切换组件
              AuthTabBar(
                selectedIndex: _tabIndex,
                onTabChanged: (index) {
                  if (_tabIndex != index) {
                    setState(() {
                      _tabIndex = index;
                      _accountCtrl.clear();
                    });
                  }
                },
                primaryColor: _primaryPurple,
              ),
              SizedBox(height: 30.h),

              if (isPhoneMode)
                GestureDetector(
                  onTap: () => CountryPickerSheet.show(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: _lineColor, width: 1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          viewModel.currentCountry != null
                              ? '${viewModel.currentCountry!.name} (${viewModel.currentCountry!.phoneCountryCode})'
                              : '选择国家/地区',
                          style: TextStyle(color: _textColor, fontSize: 14.sp),
                        ),
                        Icon(Icons.arrow_forward_ios, color: _hintColor, size: 14.w),
                      ],
                    ),
                  ),
                ),

              // 账号输入框
              AuthUnderlinedField(
                controller: _accountCtrl,
                hintText: isPhoneMode ? '请输入手机号' : '请输入邮箱',
                keyboardType: isPhoneMode ? TextInputType.phone : TextInputType.emailAddress,
                trailing: _accountCtrl.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () => setState(() => _accountCtrl.clear()),
                        child: Icon(Icons.cancel, color: Colors.grey.shade400, size: 18.w),
                      )
                    : null,
              ),

              // 验证码输入框
              AuthUnderlinedField(
                controller: _codeCtrl,
                hintText: '请输入验证码',
                icon: Icons.verified_user_outlined,
                keyboardType: TextInputType.number,
                trailing: ValueListenableBuilder<bool>(
                  valueListenable: _isSendingCode,
                  builder: (context, isSending, child) {
                    return SizedBox(
                      height: 32.h,
                      child: ElevatedButton(
                        onPressed: (_countdown > 0 || isSending)
                            ? null
                            : () async {
                                final target = _accountCtrl.text.trim();
                                if (target.isEmpty) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(SnackBar(content: Text(isPhoneMode ? '请输入手机号' : '请输入邮箱')));
                                  return;
                                }
                                FocusManager.instance.primaryFocus?.unfocus();
                                _isSendingCode.value = true;
                                final cooldown = await viewModel.sendVerifyCode(target, isPhoneMode);
                                if (mounted) _isSendingCode.value = false;
                                if (cooldown > 0) {
                                  _startCountdown(cooldown);
                                } else if (viewModel.hasError && mounted) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(SnackBar(content: Text(viewModel.errorMsg)));
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryPurple,
                          disabledBackgroundColor: Colors.grey.shade300,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                          padding: EdgeInsets.symmetric(horizontal: 14.w),
                        ),
                        child: isSending
                            ? SizedBox(
                                width: 14.w,
                                height: 14.w,
                                child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                _countdown > 0 ? '${_countdown}s' : '获取验证码',
                                style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
                              ),
                      ),
                    );
                  },
                ),
              ),

              // 新密码
              AuthUnderlinedField(
                controller: _passwordCtrl,
                hintText: '设置新密码',
                icon: Icons.lock_outline,
                isPassword: true,
                obscureText: _obscurePassword,
                onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
              ),

              // 确认新密码
              AuthUnderlinedField(
                controller: _confirmPasswordCtrl,
                hintText: '确认新密码',
                icon: Icons.lock_outline,
                isPassword: true,
                obscureText: _obscureConfirmPassword,
                onToggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              SizedBox(height: 35.h),

              // 提交修改按钮
              ValueListenableBuilder<bool>(
                valueListenable: _isSubmitting,
                builder: (context, isSubmitting, child) {
                  return SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : () => _handleResetPassword(viewModel, s),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
                        elevation: 0,
                      ),
                      child: isSubmitting
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              '确认修改',
                              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                            ),
                    ),
                  );
                },
              ),
              SizedBox(height: 12.h),
              Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: Text(
                    '想起密码？去登录',
                    style: TextStyle(color: _hintColor, fontSize: 13.sp),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
