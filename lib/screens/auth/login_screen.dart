import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import 'auth_widgets.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await action();
      // AuthGate swaps to the app; drop the auth routes above it.
      if (mounted && AuthService.instance.currentUser != null) Navigator.of(context).popUntil((r) => r.isFirst);
    } on AuthFailure catch (e) {
      if (mounted) showMessage(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _run(() => AuthService.instance.signIn(email: _email.text, password: _password.text));
  }

  Future<void> _forgotPassword() async {
    if (AuthService.validateEmail(_email.text) != null) {
      showMessage(context, 'Enter your email above first');
      return;
    }
    try {
      await AuthService.instance.sendPasswordReset(_email.text);
      if (mounted) showMessage(context, 'If an account exists, a reset link has been sent.');
    } on AuthFailure catch (e) {
      if (mounted) showMessage(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kBackground,
        appBar: AppBar(backgroundColor: kBackground),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), children: [
              const Text('Welcome back', style: TextStyle(color: kText, fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('Log in to continue managing your money.', style: TextStyle(color: kMuted)),
              const SizedBox(height: 28),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: authInput('Email', Icons.mail_outline),
                validator: AuthService.validateEmail,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                enableSuggestions: false,
                autocorrect: false,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: authInput('Password', Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )),
                validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _busy ? null : _forgotPassword, child: const Text('Forgot password?')),
              ),
              const SizedBox(height: 8),
              PrimaryButton(label: 'Log in', loading: _busy, onPressed: _submit),
              const OrDivider(),
              GoogleButton(onPressed: _busy ? null : () => _run(() => AuthService.instance.signInWithGoogle())),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text("Don't have an account?", style: TextStyle(color: kMuted)),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text('Register'),
                ),
              ]),
            ]),
          ),
        ),
      );
}
