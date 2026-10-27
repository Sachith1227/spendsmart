import 'package:flutter/material.dart';

import '../../models/savings_goal.dart';
import '../../theme/app_colors.dart';

class CreateSavingsGoalDialog extends StatefulWidget {
  const CreateSavingsGoalDialog({super.key});

  @override
  State<CreateSavingsGoalDialog> createState() => _CreateSavingsGoalDialogState();
}

class _CreateSavingsGoalDialogState extends State<CreateSavingsGoalDialog> {
  static const _icons = [
    Icons.savings_outlined,
    Icons.shield_outlined,
    Icons.laptop_mac_outlined,
    Icons.flight_takeoff_outlined,
    Icons.directions_car_outlined,
    Icons.home_outlined,
    Icons.school_outlined,
    Icons.phone_iphone_outlined,
  ];

  final _title = TextEditingController();
  final _target = TextEditingController();
  final _saved = TextEditingController();
  IconData _icon = _icons.first;
  String? _titleError, _targetError, _savedError;

  @override
  void dispose() {
    _title.dispose();
    _target.dispose();
    _saved.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    final target = double.tryParse(_target.text.replaceAll(',', '').trim());
    final savedText = _saved.text.replaceAll(',', '').trim();
    final saved = savedText.isEmpty ? 0.0 : double.tryParse(savedText);
    setState(() {
      _titleError = title.isEmpty ? 'Enter a goal name' : null;
      _targetError = target == null || target <= 0 ? 'Enter a valid target' : null;
      _savedError = saved == null || saved < 0 ? 'Enter a valid amount' : null;
    });
    if (_titleError != null || _targetError != null || _savedError != null) return;
    Navigator.pop(context, SavingsGoal(title: title, target: target!, saved: saved!, icon: _icon));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Create savings goal'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(controller: _title, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(labelText: 'Goal name', errorText: _titleError)),
            const SizedBox(height: 12),
            TextField(controller: _target, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Target amount (LKR)', errorText: _targetError)),
            const SizedBox(height: 12),
            TextField(controller: _saved, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Already saved (optional)', errorText: _savedError)),
            const SizedBox(height: 14),
            const Text('Icon', style: TextStyle(color: kMuted, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _icons
                  .map((icon) => InkWell(
                        onTap: () => setState(() => _icon = icon),
                        customBorder: const CircleBorder(),
                        child: CircleAvatar(
                          backgroundColor: _icon == icon ? kGreen : kSoftBlue,
                          child: Icon(icon, color: _icon == icon ? Colors.white : kGreen, size: 20),
                        ),
                      ))
                  .toList(),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: _submit, child: const Text('Create')),
        ],
      );
}
