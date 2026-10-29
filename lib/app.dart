import 'package:flutter/material.dart';

import 'screens/auth/auth_gate.dart';
import 'theme/app_theme.dart';

class SpendSmartApp extends StatelessWidget {
  const SpendSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpendSmart',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AuthGate(),
    );
  }
}
