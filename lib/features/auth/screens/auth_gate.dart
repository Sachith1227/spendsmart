import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:spendsmart/data/services/auth_service.dart';
import 'package:spendsmart/features/shell/spend_smart_shell.dart';
import 'package:spendsmart/features/auth/screens/welcome_screen.dart';

/// Shows the app when signed in, otherwise the welcome flow.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
        stream: AuthService.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final user = snapshot.data;
          // Key by uid so a different account gets fresh in-memory state.
          return user == null ? const WelcomeScreen() : SpendSmartShell(key: ValueKey(user.uid));
        },
      );
}
