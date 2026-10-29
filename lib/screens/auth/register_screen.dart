import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import 'auth_widgets.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, {String? successMessage}) async {
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted || AuthService.instance.currentUser == null) return;
      if (successMessage != null) showMessage(context, successMessage);
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on AuthFailure catch (e) {
      if (mounted) showMessage(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _run(
      () => AuthService.instance.register(name: _name.text, email: _email.text, password: _password.text),
      successMessage: 'Account created. Check your inbox to verify your email.',
    );
  }

  Widget _visibilityToggle() => IconButton(
        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
        onPressed: () => setState(() => _obscure = !_obscure),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kBackground,
        appBar: AppBar(backgroundColor: kBackground),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), children: [
              const Text('Create account', style: TextStyle(color: kText, fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('Start tracking your spending in minutes.', style: TextStyle(color: kMuted)),
              const SizedBox(height: 28),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.next,
                decoration: authInput('Full name', Icons.person_outline),
                validator: AuthService.validateName,
              ),
              const SizedBox(height: 14),
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
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                decoration: authInput('Password', Icons.lock_outline, suffix: _visibilityToggle()),
                validator: AuthService.validatePassword,
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 6, 4, 0),
                child: Text('8+ characters with upper & lower case, a number and a symbol.', style: TextStyle(color: kMuted, fontSize: 12)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirm,
                obscureText: _obscure,
                enableSuggestions: false,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: authInput('Confirm password', Icons.lock_outline),
                validator: (v) => v != _password.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Create account', loading: _busy, onPressed: _submit),
              const OrDivider(),
              GoogleButton(onPressed: _busy ? null : () => _run(() => AuthService.instance.signInWithGoogle())),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Already have an account?', style: TextStyle(color: kMuted)),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: const Text('Log in'),
                ),
              ]),
            ]),
          ),
        ),
      );
}
