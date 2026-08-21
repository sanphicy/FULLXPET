import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/widgets/responsive_layout.dart';
import 'package:fullxpet/routes/app_router.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF917CEE);
    final s = S.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ResponsiveFormContainer(
          maxWidth: 420,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 40),
                  SizedBox(width: 96, height: 96, child: Image.asset('assets/images/logo.png', fit: BoxFit.contain)),
                  const SizedBox(height: 16),
                  const Text(
                    'FULLX PET',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 80),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        elevation: 0,
                      ),
                      onPressed: () => context.push(AppRoutes.login),
                      child: Text(
                        s.login,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD4CCF7), width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      onPressed: () => context.push(AppRoutes.register),
                      child: Text(
                        s.register,
                        style: const TextStyle(color: primaryPurple, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
