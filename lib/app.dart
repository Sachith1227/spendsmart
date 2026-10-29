import 'package:flutter/material.dart';

import 'package:spendsmart/features/auth/screens/auth_gate.dart';
import 'package:spendsmart/core/theme/app_theme.dart';

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
