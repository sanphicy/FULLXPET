import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/models/country_dto.dart';
import 'package:fullxpet/common/widgets/privacy_bottom_sheet.dart';
import 'package:fullxpet/common/widgets/responsive_layout.dart';
import 'package:fullxpet/features/auth/viewmodels/login_view_model.dart';
import 'package:fullxpet/features/auth/widgets/country_picker_sheet.dart';
import 'package:fullxpet/routes/app_router.dart';
import 'package:fullxpet/common/config/app_constants.dart';

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

  Future<void> _handleLogin(LoginViewModel viewModel, S s) async {
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.emptyAccountOrPassword)));
      return;
    }
    final bool isEmail = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(account);

    _isSubmitting.value = true;
    final success = await viewModel.login(account, password, isEmail: isEmail);
    if (mounted) _isSubmitting.value = false;

    if (success && mounted) {
      context.go(AppRoutes.home);
    } else if (viewModel.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(viewModel.errorMsg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final viewModel = context.read<LoginViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Selector<LoginViewModel, CountryDto?>(
            selector: (_, vm) => vm.currentCountry,
            builder: (context, currentCountry, _) {
              return GestureDetector(
                onTap: () async {
                  final country = await CountryPickerSheet.show(context);
                  if (country != null && mounted) {
                    viewModel.switchCountry(country);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFF3F2F8), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentCountry?.name ?? s.selectCountry,
                        style: TextStyle(fontSize: 12, color: _primaryPurple, fontWeight: FontWeight.bold),
                      ),
                      Icon(Icons.arrow_drop_down, color: _primaryPurple, size: 18),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveFormContainer(
          maxWidth: 420,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                SizedBox(width: 80, height: 80, child: Image.asset('assets/images/logo.png', fit: BoxFit.contain)),
                const SizedBox(height: 16),
                Text(
                  'FULLX PET',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textColor, letterSpacing: 1.1),
                ),
                const SizedBox(height: 32),

                Container(
                  height: 48,
                  decoration: BoxDecoration(color: _inputBgColor, borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, color: _hintColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _accountCtrl,
                          style: TextStyle(color: _textColor, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: s.emailHint,
                            hintStyle: TextStyle(color: _hintColor, fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  height: 48,
                  decoration: BoxDecoration(color: _inputBgColor, borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                        child: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: _hintColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          style: TextStyle(color: _textColor, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: s.passwordHint,
                            hintStyle: TextStyle(color: _hintColor, fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.forgotPassword),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(s.forgotPassword, style: TextStyle(color: _hintColor, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 24),

                ValueListenableBuilder<bool>(
                  valueListenable: _isSubmitting,
                  builder: (context, isSubmitting, child) {
                    return SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : () => _handleLogin(viewModel, s),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                s.login,
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.push(AppRoutes.register),
                  child: Text(s.register, style: TextStyle(color: _hintColor, fontSize: 14)),
                ),
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                                  extra: {'title': s.userAgreement, 'url': AppConstants.userAgreementUrl},
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
                                  extra: {'title': s.privacyPolicy, 'url': AppConstants.privacyPolicyUrl},
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
