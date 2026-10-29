import 'package:flutter/material.dart';

import 'package:spendsmart/core/theme/app_colors.dart';
import 'package:spendsmart/core/utils/formatters.dart';

class BudgetItem {
  BudgetItem({
    String? id,
    required this.name,
    required this.category,
    required this.limit,
    required this.icon,
    required this.color,
    this.spent = 0,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  final String id;
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

  /// `spent` is derived from transactions, so it is not stored.
  Map<String, dynamic> toMap() => {'name': name, 'category': category, 'limit': limit};

  factory BudgetItem.fromMap(String id, Map<String, dynamic> map) {
    final category = map['category'] as String? ?? 'Other';
    return BudgetItem(
      id: id,
      name: map['name'] as String? ?? category,
      category: category,
      limit: (map['limit'] as num?)?.toDouble() ?? 0,
      icon: categoryIcon(category),
      color: kGreen,
    );
  }
}
