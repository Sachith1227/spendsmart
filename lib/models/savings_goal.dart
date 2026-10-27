import 'package:flutter/material.dart';

class SavingsGoal {
  SavingsGoal({
    required this.title,
    required this.target,
    required this.icon,
    this.saved = 0,
  });

  final String title;
  final double target;
  final IconData icon;
  double saved;

  double get progress => target <= 0 ? 0.0 : (saved / target).clamp(0.0, 1.0).toDouble();
  bool get isComplete => saved >= target;
}
