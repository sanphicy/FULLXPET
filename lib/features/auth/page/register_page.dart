import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/models/country_dto.dart';
import 'package:fullxpet/common/widgets/privacy_bottom_sheet.dart';
import 'package:fullxpet/common/widgets/responsive_layout.dart';
import 'package:fullxpet/features/auth/viewmodels/register_view_model.dart';
import 'package:fullxpet/features/auth/widgets/auth_tab_bar.dart';
import 'package:fullxpet/features/auth/widgets/auth_underlined_field.dart';
import 'package:fullxpet/features/auth/widgets/country_picker_sheet.dart';
import 'package:fullxpet/routes/app_router.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
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

  Future<void> _handleRegister(RegisterViewModel viewModel, S s) async {
    final account = _accountCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    final pwd = _passwordCtrl.text.trim();
    final confirmPwd = _confirmPasswordCtrl.text.trim();

    if (account.isEmpty || code.isEmpty || pwd.isEmpty || confirmPwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.emptyAccountOrPassword)));
      return;
    }

    final isPhoneMode = _tabIndex == 0;
    if (isPhoneMode) {
      final bool isPhone = RegExp(r'^\d{5,15}$').hasMatch(account);
      if (!isPhone) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.invalidAccountFormat)));
        return;
      }
    } else {
      final bool isEmail = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(account);
      if (!isEmail) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.invalidAccountFormat)));
        return;
      }
    }

    if (pwd != confirmPwd) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.passwordMismatch)));
      return;
    }

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

    final success = await viewModel.register(account: account, password: pwd, code: code, isPhoneMode: isPhoneMode);

    if (mounted) _isSubmitting.value = false;
    if (success && mounted) {
      context.go(AppRoutes.login);
    } else if (viewModel.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(viewModel.errorMsg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final viewModel = context.read<RegisterViewModel>();
    final isPhoneMode = _tabIndex == 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: _textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ResponsiveFormContainer(
          maxWidth: 420,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    s.createAccount,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textColor),
                  ),
                ),
                const SizedBox(height: 20),

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
                const SizedBox(height: 24),

                Selector<RegisterViewModel, CountryDto?>(
                  selector: (_, vm) => vm.currentCountry,
                  builder: (context, currentCountry, _) {
                    final String displayLabel = currentCountry != null
                        ? (isPhoneMode
                              ? '${currentCountry.name} (${currentCountry.phoneCountryCode})'
                              : currentCountry.name)
                        : s.selectCountry;

                    return GestureDetector(
                      onTap: () async {
                        final country = await CountryPickerSheet.show(context);
                        if (country != null && mounted) {
                          viewModel.switchCountry(country);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: _lineColor, width: 1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.public_outlined, color: _textColor, size: 20),
                                const SizedBox(width: 10),
                                Text(displayLabel, style: TextStyle(color: _textColor, fontSize: 15)),
                              ],
                            ),
                            Icon(Icons.arrow_forward_ios, color: _hintColor, size: 14),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                AuthUnderlinedField(
                  controller: _accountCtrl,
                  hintText: isPhoneMode ? s.phoneLogin : s.emailLogin,
                  keyboardType: isPhoneMode ? TextInputType.phone : TextInputType.emailAddress,
                  trailing: _accountCtrl.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () => setState(() => _accountCtrl.clear()),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: Icon(Icons.cancel, color: Colors.grey.shade400, size: 18),
                          ),
                        )
                      : null,
                ),

                AuthUnderlinedField(
                  controller: _codeCtrl,
                  hintText: s.enterCode,
                  icon: Icons.verified_user_outlined,
                  keyboardType: TextInputType.number,
                  trailing: ValueListenableBuilder<bool>(
                    valueListenable: _isSendingCode,
                    builder: (context, isSending, child) {
                      return SizedBox(
                        height: 32,
                        child: ElevatedButton(
                          onPressed: (_countdown > 0 || isSending)
                              ? null
                              : () async {
                                  final target = _accountCtrl.text.trim();
                                  if (target.isEmpty) {
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(SnackBar(content: Text(isPhoneMode ? s.phoneLogin : s.emailLogin)));
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          child: isSending
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  _countdown > 0 ? '${_countdown}s' : s.sendCode,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ),

                AuthUnderlinedField(
                  controller: _passwordCtrl,
                  hintText: s.passwordHint,
                  icon: Icons.lock_outline,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                ),

                AuthUnderlinedField(
                  controller: _confirmPasswordCtrl,
                  hintText: s.confirmPasswordHint,
                  icon: Icons.lock_outline,
                  isPassword: true,
                  obscureText: _obscureConfirmPassword,
                  onToggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                const SizedBox(height: 32),

                ValueListenableBuilder<bool>(
                  valueListenable: _isSubmitting,
                  builder: (context, isSubmitting, child) {
                    return SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : () => _handleRegister(viewModel, s),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(s.register, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                Center(
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: Text(s.hasAccountGoLogin, style: TextStyle(color: _hintColor, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _agreedToTerms ? _primaryPurple : _hintColor, width: 1),
                          color: _agreedToTerms ? _primaryPurple : Colors.transparent,
                        ),
                        child: _agreedToTerms ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(color: _hintColor, fontSize: 12),
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
