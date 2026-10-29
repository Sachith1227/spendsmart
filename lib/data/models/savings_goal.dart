import 'package:flutter/material.dart';

/// Icons a goal can use; goals store an index into this list.
const kGoalIcons = [
  Icons.savings_outlined,
  Icons.shield_outlined,
  Icons.laptop_mac_outlined,
  Icons.flight_takeoff_outlined,
  Icons.directions_car_outlined,
  Icons.home_outlined,
  Icons.school_outlined,
  Icons.phone_iphone_outlined,
];

class SavingsGoal {
  SavingsGoal({
    String? id,
    required this.title,
    required this.target,
    required this.icon,
    this.saved = 0,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  final String id;
  final String title;
  final double target;
  final IconData icon;
  double saved;

  double get progress => target <= 0 ? 0.0 : (saved / target).clamp(0.0, 1.0).toDouble();
  bool get isComplete => saved >= target;

  Map<String, dynamic> toMap() {
    final iconIndex = kGoalIcons.indexOf(icon);
    return {'title': title, 'target': target, 'saved': saved, 'iconIndex': iconIndex < 0 ? 0 : iconIndex};
  }

  factory SavingsGoal.fromMap(String id, Map<String, dynamic> map) {
    final iconIndex = (map['iconIndex'] as num?)?.toInt() ?? 0;
    return SavingsGoal(
      id: id,
      title: map['title'] as String? ?? '',
      target: (map['target'] as num?)?.toDouble() ?? 0,
      saved: (map['saved'] as num?)?.toDouble() ?? 0,
      icon: kGoalIcons[iconIndex.clamp(0, kGoalIcons.length - 1)],
    );
  }
}
