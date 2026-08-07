import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:fullxpet/routes/app_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/features/auth/auth_provider.dart';
import 'package:fullxpet/common/widgets/privacy_bottom_sheet.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  int _tabIndex = 0; // 0: 手机号, 1: 邮箱
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoginProvider>().fetchCountries();
    });
  }

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

  void _showCountryPicker(BuildContext context, LoginProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Text(
                  "选择国家或地区",
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: _textColor),
                ),
              ),
              Divider(height: 1, color: _lineColor),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: provider.countryList.length,
                  itemBuilder: (context, index) {
                    final country = provider.countryList[index];
                    final isSelected = provider.selectedCountry?.countryCode == country.countryCode;
                    return ListTile(
                      title: Text(
                        country.name,
                        style: TextStyle(
                          color: isSelected ? _primaryPurple : _textColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: Text(country.phoneCountryCode, style: TextStyle(color: _hintColor)),
                      onTap: () {
                        provider.selectCountry(country);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 处理注册提交
  Future<void> _handleRegister(LoginProvider provider, S s) async {
    final account = _accountCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    final pwd = _passwordCtrl.text.trim();
    final confirmPwd = _confirmPasswordCtrl.text.trim();

    if (account.isEmpty || code.isEmpty || pwd.isEmpty || confirmPwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写所有必填项')));
      return;
    }

    final isPhoneMode = _tabIndex == 0;

    // 格式判断
    if (isPhoneMode) {
      final bool isPhone = RegExp(r'^\d{5,15}$').hasMatch(account);
      if (!isPhone) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入正确的手机号码')));
        return;
      }
    } else {
      final bool isEmail = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(account);
      if (!isEmail) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入正确的邮箱格式')));
        return;
      }
    }

    if (pwd != confirmPwd) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('两次输入的密码不一致')));
      return;
    }

    // 隐私协议校验
    if (!_agreedToTerms) {
      final allowed = await PrivacyBottomSheet.show(context, _primaryPurple);
      if (allowed) {
        setState(() => _agreedToTerms = true);
      } else {
        return;
      }
    }

    FocusManager.instance.primaryFocus?.unfocus();
    _isSubmitting.value = true;

    final phonePrefix = provider.selectedCountry?.phoneCountryCode ?? "+86";
    final countryCode = provider.selectedCountry?.countryCode ?? "CN";

    // 调用 provider 智能注册方法
    final success = await provider.register(
      account: account,
      password: pwd,
      code: code,
      countryCode: countryCode,
      isPhoneMode: isPhoneMode,
      phoneCountryCode: phonePrefix,
    );

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
              Center(
                child: SizedBox(
                  width: 80.w,
                  height: 80.w,
                  child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                '创建新账号',
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: _textColor),
              ),
              SizedBox(height: 25.h),
              // 手机号 / 邮箱 切换 Tab
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
                        child: FractionalTranslation(
                          translation: Offset.zero,
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
                                      Icons.email_outlined,
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
              // 国家/地区选择
              GestureDetector(
                onTap: () => _showCountryPicker(context, provider),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: _lineColor, width: 1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        provider.selectedCountry != null
                            ? '${provider.selectedCountry!.name} (${provider.selectedCountry!.phoneCountryCode})'
                            : '选择国家/地区',
                        style: TextStyle(color: _textColor, fontSize: 14.sp),
                      ),
                      Icon(Icons.arrow_forward_ios, color: _hintColor, size: 14.w),
                    ],
                  ),
                ),
              ),
              // 账号（手机号/邮箱）输入框
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
                          hintText: isPhoneMode ? '请输入手机号码' : '请输入邮箱地址',
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
              // 验证码输入框
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
                                    final cooldown = await provider.sendVerifyCode(
                                      target,
                                      isPhoneMode ? "Phone" : "Email",
                                      purpose: "register",
                                    );
                                    if (mounted) _isSendingCode.value = false;
                                    if (cooldown > 0) {
                                      _startCountdown(cooldown);
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
                                    _countdown > 0 ? '${_countdown}s' : '发送验证码',
                                    style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // 密码输入框
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
                          hintText: '设置密码',
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
              // 确认密码输入框
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
                          hintText: '确认密码',
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
                '密码需为 8-16 位，包含字母与数字',
                style: TextStyle(fontSize: 11.sp, color: _hintColor),
              ),
              SizedBox(height: 35.h),
              // 注册按钮
              ValueListenableBuilder<bool>(
                valueListenable: _isSubmitting,
                builder: (context, isSubmitting, child) {
                  return SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : () => _handleRegister(provider, s),
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
                              '注册',
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
                    '已有账号？去登录',
                    style: TextStyle(color: _hintColor, fontSize: 13.sp),
                  ),
                ),
              ),
              SizedBox(height: 30.h),
              // 协议勾选
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
