import 'package:flutter/material.dart';

import 'package:spendsmart/data/models/budget_item.dart';
import 'package:spendsmart/core/theme/app_colors.dart';
import 'package:spendsmart/core/utils/formatters.dart';
import 'package:spendsmart/core/widgets/common.dart';

class BudgetCard extends StatelessWidget {
  const BudgetCard({super.key, required this.budget, this.onTap});
  final BudgetItem budget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final warning = budget.usedRatio >= .9;
    final percent = (budget.usedRatio * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(21),
          child: Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(21), border: Border.all(color: kCardBorder)),
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: budget.color.withValues(alpha: .10), borderRadius: BorderRadius.circular(14)),
                  child: Icon(budget.icon, color: budget.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(budget.name, style: const TextStyle(color: kText, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 5),
                    Text('${money(budget.spent)} of ${money(budget.limit)}', style: const TextStyle(color: kMuted, fontSize: 11)),
                  ]),
                ),
                const SizedBox(width: 5),
                StatusPill(text: warning ? '$percent% used!' : '$percent% spent', warning: warning),
              ]),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(value: budget.progress, minHeight: 8, backgroundColor: kSoftBlue, color: warning ? kRed : budget.color),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: Text('Remaining: ${money(budget.remaining)}', style: TextStyle(color: budget.remaining == 0 ? kRed : kMuted, fontSize: 11, fontWeight: FontWeight.w600))),
                Text(budget.usedRatio > 1 ? 'Over limit' : warning ? 'Near limit' : 'On track', style: TextStyle(color: warning ? kRed : kGreen, fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
