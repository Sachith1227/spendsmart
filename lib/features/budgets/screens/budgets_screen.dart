import 'package:flutter/material.dart';

import 'package:spendsmart/data/models/budget_item.dart';
import 'package:spendsmart/data/models/savings_goal.dart';
import 'package:spendsmart/data/state/app_state.dart';
import 'package:spendsmart/core/theme/app_colors.dart';
import 'package:spendsmart/core/utils/formatters.dart';
import 'package:spendsmart/features/budgets/widgets/budget_card.dart';
import 'package:spendsmart/core/widgets/common.dart';
import 'package:spendsmart/core/widgets/amount_dialog.dart';
import 'package:spendsmart/features/budgets/widgets/create_budget_dialog.dart';
import 'package:spendsmart/features/budgets/widgets/create_savings_goal_dialog.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key, required this.state, required this.onNotifications, required this.onProfile});
  final AppState state;
  final VoidCallback onNotifications, onProfile;

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  bool _showSavings = false;

  AppState get state => widget.state;

  Future<void> _createBudget() async {
    final result = await showDialog<BudgetItem>(
      context: context,
      builder: (_) => CreateBudgetDialog(existingCategories: state.budgets.map((b) => b.category).toSet()),
    );
    if (result == null || !mounted) return;
    state.addBudget(result);
    showMessage(context, 'Budget "${result.name}" created');
  }

  Future<void> _budgetActions(BudgetItem budget) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Change limit'), onTap: () => Navigator.pop(sheetContext, 'edit')),
          ListTile(leading: const Icon(Icons.delete_outline, color: kRed), title: const Text('Delete budget', style: TextStyle(color: kRed)), onTap: () => Navigator.pop(sheetContext, 'delete')),
        ]),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'edit') {
      final limit = await showAmountDialog(context, title: 'Monthly limit for ${budget.name}', initial: budget.limit, confirmLabel: 'Save');
      if (limit == null || !mounted) return;
      state.updateBudgetLimit(budget, limit);
      showMessage(context, 'Limit updated');
    } else {
      state.deleteBudget(budget);
      showMessage(context, 'Budget deleted');
    }
  }

  Future<void> _createGoal() async {
    final result = await showDialog<SavingsGoal>(context: context, builder: (_) => const CreateSavingsGoalDialog());
    if (result == null || !mounted) return;
    state.addGoal(result);
    showMessage(context, 'Savings goal "${result.title}" created');
  }

  Future<void> _goalActions(SavingsGoal goal) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.add_circle_outline, color: kGreen), title: const Text('Add money'), onTap: () => Navigator.pop(sheetContext, 'add')),
          ListTile(leading: const Icon(Icons.remove_circle_outline), title: const Text('Withdraw money'), onTap: () => Navigator.pop(sheetContext, 'withdraw')),
          ListTile(leading: const Icon(Icons.delete_outline, color: kRed), title: const Text('Delete goal', style: TextStyle(color: kRed)), onTap: () => Navigator.pop(sheetContext, 'delete')),
        ]),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'delete') {
      state.deleteGoal(goal);
      showMessage(context, 'Goal deleted');
      return;
    }
    final adding = action == 'add';
    final amount = await showAmountDialog(context, title: adding ? 'Add to ${goal.title}' : 'Withdraw from ${goal.title}', confirmLabel: adding ? 'Add' : 'Withdraw');
    if (amount == null || !mounted) return;
    if (!adding && amount > goal.saved) {
      showMessage(context, 'You only have ${money(goal.saved)} saved.');
      return;
    }
    state.contributeToGoal(goal, adding ? amount : -amount);
    showMessage(context, goal.isComplete ? '🎉 Goal reached!' : 'Goal updated');
  }

  @override
  Widget build(BuildContext context) {
    final budgets = state.budgets;
    final totalSpent = budgets.fold<double>(0, (s, b) => s + b.spent);
    final totalLimit = budgets.fold<double>(0, (s, b) => s + b.limit);
    final totalRemaining = (totalLimit - totalSpent).clamp(0.0, double.infinity).toDouble();
    final progress = totalLimit == 0 ? 0.0 : (totalSpent / totalLimit).clamp(0.0, 1.0).toDouble();
    final now = DateTime.now();
    final daysLeft = DateTime(now.year, now.month + 1, 0).day - now.day + 1;
    final weeksLeft = (daysLeft / 7).clamp(1.0, 5.0);

    return SafeArea(
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 110), children: [
        AppHeader(notificationCount: state.unreadNotificationCount, onNotifications: widget.onNotifications, onProfile: widget.onProfile, showTagline: false),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: kSoftBlue, borderRadius: BorderRadius.circular(17)),
          child: Row(children: [
            _BudgetTab(label: 'Monthly Budgets', selected: !_showSavings, onTap: () => setState(() => _showSavings = false)),
            _BudgetTab(label: 'Savings Goals', selected: _showSavings, onTap: () => setState(() => _showSavings = true)),
          ]),
        ),
        const SizedBox(height: 20),
        if (_showSavings)
          _SavingsGoalsCard(goals: state.goals, onCreate: _createGoal, onGoalTap: _goalActions)
        else ...[
          AppCard(
            padding: const EdgeInsets.all(21),
            radius: 24,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 44, height: 44, decoration: const BoxDecoration(color: kSoftBlue, shape: BoxShape.circle), child: const Icon(Icons.calendar_month_outlined, color: kGreen)),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${kMonths[now.month - 1].toUpperCase()} OVERVIEW', style: const TextStyle(color: kMuted, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w700)),
                    const Text('Budget overview', style: TextStyle(fontSize: 20, color: kText, fontWeight: FontWeight.w800)),
                  ]),
                ),
                StatusPill(text: '${(progress * 100).round()}% used', warning: progress > .9),
              ]),
              const SizedBox(height: 24),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Spent so far', style: TextStyle(color: kMuted, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(money(totalSpent), style: const TextStyle(color: kText, fontSize: 23, fontWeight: FontWeight.w800)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Text('Total cap', style: TextStyle(color: kMuted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(money(totalLimit), style: const TextStyle(color: kMuted, fontSize: 16, fontWeight: FontWeight.w700)),
                ]),
              ]),
              const SizedBox(height: 18),
              ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: progress, minHeight: 11, color: progress > .9 ? kRed : kGreen, backgroundColor: kSoftBlue)),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: _BudgetStat(title: 'Remaining', value: money(totalRemaining), icon: Icons.account_balance_wallet_outlined, color: kText)),
                const SizedBox(width: 10),
                Expanded(child: _BudgetStat(title: 'Safe weekly pace', value: money(totalRemaining / weeksLeft), icon: Icons.speed_outlined, color: kGreen)),
              ]),
            ]),
          ),
          const SizedBox(height: 25),
          Row(children: [
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Category budgets', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kText)),
                SizedBox(height: 3),
                Text('Tap a budget to edit or delete it', style: TextStyle(color: kMuted, fontSize: 12)),
              ]),
            ),
            FilledButton.icon(
              onPressed: _createBudget,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create'),
              style: FilledButton.styleFrom(backgroundColor: kSoftBlue, foregroundColor: kText),
            ),
          ]),
          const SizedBox(height: 13),
          if (budgets.isEmpty)
            const EmptyState(icon: Icons.pie_chart_outline, title: 'No budgets yet', message: 'Create a budget to start tracking your limits.')
          else
            ...budgets.map((b) => BudgetCard(budget: b, onTap: () => _budgetActions(b))),
        ],
      ]),
    );
  }
}

class _BudgetTab extends StatelessWidget {
  const _BudgetTab({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 5),
            decoration: BoxDecoration(color: selected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(13)),
            child: Center(child: Text(label, style: TextStyle(color: selected ? kText : kMuted, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, fontSize: 12))),
          ),
        ),
      );
}

class _BudgetStat extends StatelessWidget {
  const _BudgetStat({required this.title, required this.value, required this.icon, required this.color});
  final String title, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: kBackground, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 5),
            Expanded(child: Text(title, style: const TextStyle(color: kMuted, fontSize: 10))),
          ]),
          const SizedBox(height: 8),
          FittedBox(alignment: Alignment.centerLeft, fit: BoxFit.scaleDown, child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 17))),
        ]),
      );
}

class _SavingsGoalsCard extends StatelessWidget {
  const _SavingsGoalsCard({required this.goals, required this.onCreate, required this.onGoalTap});
  final List<SavingsGoal> goals;
  final VoidCallback onCreate;
  final ValueChanged<SavingsGoal> onGoalTap;

  @override
  Widget build(BuildContext context) {
    final totalSaved = goals.fold<double>(0, (s, g) => s + g.saved);
    return AppCard(
      padding: const EdgeInsets.all(21),
      radius: 23,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Your savings goals', style: TextStyle(color: kText, fontSize: 21, fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Text(goals.isEmpty ? 'Small steps make a big difference.' : 'Total saved: ${money(totalSaved)} · tap a goal to update it', style: const TextStyle(color: kMuted)),
        const SizedBox(height: 18),
        if (goals.isEmpty)
          const EmptyState(icon: Icons.savings_outlined, title: 'No goals yet', message: 'Create a goal to start saving.')
        else
          for (final g in goals) ...[
            _GoalRow(goal: g, onTap: () => onGoalTap(g)),
            const SizedBox(height: 14),
          ],
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Create savings goal'),
            style: FilledButton.styleFrom(backgroundColor: kGreen, padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),
      ]),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.goal, required this.onTap});
  final SavingsGoal goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(children: [
            Row(children: [
              Container(width: 42, height: 42, decoration: const BoxDecoration(color: kSoftBlue, shape: BoxShape.circle), child: Icon(goal.isComplete ? Icons.check : goal.icon, color: kGreen)),
              const SizedBox(width: 10),
              Expanded(child: Text(goal.title, style: const TextStyle(color: kText, fontWeight: FontWeight.w700))),
              Text('${(goal.progress * 100).round()}%', style: const TextStyle(color: kGreen, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: goal.progress, minHeight: 8, color: kGreen, backgroundColor: kSoftBlue)),
            const SizedBox(height: 5),
            Row(children: [
              Text(money(goal.saved), style: const TextStyle(color: kText, fontSize: 11, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('Goal ${money(goal.target)}', style: const TextStyle(color: kMuted, fontSize: 11)),
            ]),
          ]),
        ),
      );
}
