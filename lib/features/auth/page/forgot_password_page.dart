import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/features/auth/auth_provider.dart';
import 'package:fullxpet/routes/app_router.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  // 控制“手机号”/“邮箱” Tab 切换（0: 手机号, 1: 邮箱）
  int _tabIndex = 0;

  final TextEditingController _accountCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();

  final ValueNotifier<bool> _isSubmitting = ValueNotifier(false);
  final ValueNotifier<bool> _isSendingCode = ValueNotifier(false);

  bool _agreedToTerms = false;
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

  void _startCountdown() {
    setState(() => _countdown = 60);
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

  /// 协议允许/拒绝 底部弹窗
  Future<bool> _showPrivacyBottomSheet(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      isDismissible: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '为给你提供更好的服务',
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: _textColor),
                ),
                SizedBox(height: 16.h),
                Text(
                  '允许我们在必要场景下，合理使用你的个人信息，并充分保障你的合法权利。\n请你在使用前仔细查阅以下协议条款，点击“允许”即表示你已阅读并同意对应的协议内容。',
                  style: TextStyle(fontSize: 13.sp, color: const Color(0xFF666666), height: 1.5),
                ),
                SizedBox(height: 16.h),
                Wrap(
                  spacing: 12.w,
                  children: [
                    Text(
                      '《用户协议》',
                      style: TextStyle(fontSize: 13.sp, color: _primaryPurple),
                    ),
                    Text(
                      '《隐私声明》',
                      style: TextStyle(fontSize: 13.sp, color: _primaryPurple),
                    ),
                    Text(
                      '《商家隐私声明》',
                      style: TextStyle(fontSize: 13.sp, color: _primaryPurple),
                    ),
                  ],
                ),
                SizedBox(height: 30.h),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48.h,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: const Color(0xFF999999), width: 1.w),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
                          ),
                          child: Text(
                            '绝 拒',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: const Color(0xFF666666),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: SizedBox(
                        height: 48.h,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryPurple,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
                          ),
                          child: Text(
                            '允 许',
                            style: TextStyle(fontSize: 16.sp, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  /// 提交重置密码
  Future<void> _handleResetPassword(LoginProvider provider, S s) async {
    final account = _accountCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    final pwd = _passwordCtrl.text.trim();
    final confirmPwd = _confirmPasswordCtrl.text.trim();

    if (account.isEmpty || code.isEmpty || pwd.isEmpty || confirmPwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写完整的信息')));
      return;
    }

    if (pwd != confirmPwd) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('两次输入的密码不一致')));
      return;
    }

    // 若未勾选协议，弹出隐私弹窗
    if (!_agreedToTerms) {
      final allowed = await _showPrivacyBottomSheet(context);
      if (allowed) {
        setState(() => _agreedToTerms = true);
      } else {
        return;
      }
    }

    FocusManager.instance.primaryFocus?.unfocus();
    _isSubmitting.value = true;

    // 调用重置密码接口
    final success = await provider.resetPassword(account, pwd, code);

    if (mounted) _isSubmitting.value = false;
    if (success && mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final provider = context.watch<LoginProvider>();
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10.h),

              // 1. Logo
              Center(
                child: SizedBox(
                  width: 80.w,
                  height: 80.w,
                  child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                ),
              ),
              SizedBox(height: 20.h),

              // 2. 标题：“重置密码”
              Text(
                '忘记密码',
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: _textColor),
              ),
              SizedBox(height: 25.h),

              // 3. 手机号 / 邮箱 Tab 切换胶囊样式
              Center(
                child: Container(
                  height: 42.h,
                  width: 280.w,
                  decoration: BoxDecoration(color: const Color(0xFFF3F2F8), borderRadius: BorderRadius.circular(21.r)),
                  child: Stack(
                    children: [
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOutCubic,
                        alignment: isPhoneMode ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          width: 136.w,
                          height: 38.h,
                          margin: EdgeInsets.symmetric(horizontal: 2.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(19.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (_tabIndex != 0) {
                                  setState(() {
                                    _tabIndex = 0;
                                    _accountCtrl.clear();
                                  });
                                }
                              },
                              child: Container(
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.smartphone_outlined,
                                      size: 18.w,
                                      color: isPhoneMode ? _primaryPurple : _hintColor,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      '手机号',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: isPhoneMode ? FontWeight.bold : FontWeight.w500,
                                        color: isPhoneMode ? _primaryPurple : _hintColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (_tabIndex != 1) {
                                  setState(() {
                                    _tabIndex = 1;
                                    _accountCtrl.clear();
                                  });
                                }
                              },
                              child: Container(
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 18.w,
                                      color: !isPhoneMode ? _primaryPurple : _hintColor,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      '邮箱',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: !isPhoneMode ? FontWeight.bold : FontWeight.w500,
                                        color: !isPhoneMode ? _primaryPurple : _hintColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30.h),

              // 4. 账号/手机号/邮箱输入
              Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: _lineColor, width: 1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _accountCtrl,
                        keyboardType: isPhoneMode ? TextInputType.phone : TextInputType.emailAddress,
                        style: TextStyle(color: _textColor, fontSize: 15.sp),
                        decoration: InputDecoration(
                          hintText: isPhoneMode ? '请输入账号/手机号' : '请输入邮箱地址',
                          hintStyle: TextStyle(color: _hintColor, fontSize: 14.sp),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                      ),
                    ),
                    if (_accountCtrl.text.isNotEmpty)
                      GestureDetector(
                        onTap: () => setState(() => _accountCtrl.clear()),
                        child: Icon(Icons.cancel, color: Colors.grey.shade400, size: 18.w),
                      ),
                  ],
                ),
              ),

              // 5. 验证码
              Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: _lineColor, width: 1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_user_outlined, color: _textColor, size: 20.w),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: TextField(
                        controller: _codeCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: _textColor, fontSize: 15.sp),
                        decoration: InputDecoration(
                          hintText: '请输入验证码',
                          hintStyle: TextStyle(color: _hintColor, fontSize: 14.sp),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                      ),
                    ),
                    ValueListenableBuilder<bool>(
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
                                    final success = await provider.sendVerifyCode(
                                      target,
                                      isPhoneMode ? "Phone" : "Email",
                                    );
                                    if (mounted) _isSendingCode.value = false;
                                    if (success) {
                                      _startCountdown();
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
                                    _countdown > 0 ? '${_countdown}s后重试' : '获取验证码',
                                    style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // 6. 新密码
              Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: _lineColor, width: 1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, color: _textColor, size: 20.w),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: TextField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        style: TextStyle(color: _textColor, fontSize: 15.sp),
                        decoration: InputDecoration(
                          hintText: '请输入新密码',
                          hintStyle: TextStyle(color: _hintColor, fontSize: 14.sp),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                      child: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: _hintColor,
                        size: 20.w,
                      ),
                    ),
                  ],
                ),
              ),

              // 7. 再次输入新密码
              Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: _lineColor, width: 1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, color: _textColor, size: 20.w),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: TextField(
                        controller: _confirmPasswordCtrl,
                        obscureText: _obscureConfirmPassword,
                        style: TextStyle(color: _textColor, fontSize: 15.sp),
                        decoration: InputDecoration(
                          hintText: '请再次输入新密码',
                          hintStyle: TextStyle(color: _hintColor, fontSize: 14.sp),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      child: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: _hintColor,
                        size: 20.w,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),

              Text(
                '密码必须是8-16位英文字母、数字、字符组合(不能是纯数字)',
                style: TextStyle(fontSize: 11.sp, color: _hintColor),
              ),
              SizedBox(height: 35.h),

              // 8. 确认重置按钮
              ValueListenableBuilder<bool>(
                valueListenable: _isSubmitting,
                builder: (context, isSubmitting, child) {
                  return SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : () => _handleResetPassword(provider, s),
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
                              '确 认',
                              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                            ),
                    ),
                  );
                },
              ),
              SizedBox(height: 12.h),

              // 9. 返回登录
              Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: Text(
                    '想起密码？去登录',
                    style: TextStyle(color: _hintColor, fontSize: 13.sp),
                  ),
                ),
              ),
              SizedBox(height: 30.h),

              // 10. 协议勾选
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                        ),
                        TextSpan(text: s.andText),
                        TextSpan(
                          text: s.privacyPolicy,
                          style: TextStyle(color: _primaryPurple),
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
