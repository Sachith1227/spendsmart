import 'package:flutter/material.dart';

import 'package:spendsmart/data/models/budget_item.dart';
import 'package:spendsmart/core/theme/app_colors.dart';
import 'package:spendsmart/core/utils/formatters.dart';

class CreateBudgetDialog extends StatefulWidget {
  const CreateBudgetDialog({super.key, this.existingCategories = const {}});

  /// Categories that already have a budget; the user is warned about duplicates.
  final Set<String> existingCategories;

  @override
  State<CreateBudgetDialog> createState() => _CreateBudgetDialogState();
}

class _CreateBudgetDialogState extends State<CreateBudgetDialog> {
  static const _categories = ['Food & Groceries', 'Transport & Fuel', 'Utilities & Bills', 'Shopping & Lifestyle', 'Education & Courses', 'Other'];

  final _name = TextEditingController();
  final _limit = TextEditingController();
  late String _category = _categories.firstWhere((c) => !widget.existingCategories.contains(c), orElse: () => _categories.first);
  String? _limitError;

  @override
  void dispose() {
    _name.dispose();
    _limit.dispose();
    super.dispose();
  }

  void _submit() {
    final limit = double.tryParse(_limit.text.replaceAll(',', '').trim());
    if (limit == null || limit <= 0) {
      setState(() => _limitError = 'Enter a valid budget limit');
      return;
    }
    Navigator.pop(
      context,
      BudgetItem(
        name: _name.text.trim().isEmpty ? _category : _name.text.trim(),
        category: _category,
        limit: limit,
        icon: categoryIcon(_category),
        color: kGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Create budget'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            if (widget.existingCategories.contains(_category))
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('A budget for this category already exists. Spending will count toward both.', style: TextStyle(color: kMuted, fontSize: 11)),
              ),
            const SizedBox(height: 12),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Budget name (optional)')),
            const SizedBox(height: 12),
            TextField(
              controller: _limit,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(labelText: 'Monthly limit (LKR)', errorText: _limitError),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: _submit, child: const Text('Create')),
        ],
      );
}
