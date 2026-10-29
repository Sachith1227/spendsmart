import 'package:flutter/material.dart';

import 'package:spendsmart/data/services/auth_service.dart';
import 'package:spendsmart/core/theme/app_colors.dart';
import 'package:spendsmart/core/widgets/common.dart';
import 'package:spendsmart/features/auth/widgets/auth_widgets.dart';
import 'package:spendsmart/features/auth/screens/login_screen.dart';
import 'package:spendsmart/features/auth/screens/register_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _busy = false;

  Future<void> _google() async {
    setState(() => _busy = true);
    try {
      await AuthService.instance.signInWithGoogle();
    } on AuthFailure catch (e) {
      if (mounted) showMessage(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(children: [
              const Spacer(),
              const AppLogo(size: 84),
              const SizedBox(height: 22),
              const AppWordmark(fontSize: 36),
              const SizedBox(height: 8),
              const Text('Track spending, plan budgets and\nreach your savings goals.',
                  textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 15, height: 1.4)),
              const Spacer(),
              PrimaryButton(
                label: 'Create account',
                onPressed: _busy ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _busy ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kGreen,
                    side: const BorderSide(color: kGreen),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('I already have an account', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const OrDivider(),
              _busy ? const CircularProgressIndicator() : GoogleButton(onPressed: _google),
            ]),
          ),
        ),
      );
}
