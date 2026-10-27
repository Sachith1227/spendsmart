import 'package:flutter/material.dart';

class BudgetItem {
  BudgetItem({
    required this.name,
    required this.category,
    required this.limit,
    required this.icon,
    required this.color,
    this.spent = 0,
  });

  final String name;

  /// Budget category used to match expense transactions.
  final String category;
  double spent;
  double limit;
  final IconData icon;
  final Color color;

  double get progress => limit <= 0 ? 0.0 : (spent / limit).clamp(0.0, 1.0).toDouble();
  double get remaining => (limit - spent).clamp(0.0, double.infinity).toDouble();
  double get usedRatio => limit <= 0 ? 0.0 : spent / limit;
}
