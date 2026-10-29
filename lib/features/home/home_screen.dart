import 'package:flutter/material.dart';

import 'package:spendsmart/data/state/app_state.dart';
import 'package:spendsmart/core/theme/app_colors.dart';
import 'package:spendsmart/core/utils/formatters.dart';
import 'package:spendsmart/core/widgets/common.dart';
import 'package:spendsmart/features/analytics/widgets/spending_category_chart.dart';
import 'package:spendsmart/features/transactions/widgets/transaction_tile.dart';
import 'package:spendsmart/features/transactions/widgets/transaction_details_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.state,
    required this.onAdd,
    required this.onViewTransactions,
    required this.onViewBudgets,
    required this.onNotifications,
    required this.onProfile,
  });

  final AppState state;
  final VoidCallback onAdd, onViewTransactions, onViewBudgets, onNotifications, onProfile;

  @override
  Widget build(BuildContext context) {
    final monthlyBudget = state.monthlyBudgetLimit;
    final spent = state.monthExpenses;
    final progress = monthlyBudget <= 0 ? 0.0 : (spent / monthlyBudget).clamp(0.0, 1.0).toDouble();
    final recent = state.transactions.take(4).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          AppHeader(notificationCount: state.unreadNotificationCount, onNotifications: onNotifications, onProfile: onProfile),
          const SizedBox(height: 24),
          _BalanceCard(balance: state.balance, income: state.monthIncome, expenses: spent, onTap: onViewTransactions),
          const SizedBox(height: 25),
          Row(children: [
            const Expanded(child: Text('Monthly budget', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: kText))),
            Text('${(progress * 100).round()}% used', style: TextStyle(color: progress > .9 ? kRed : kGreen, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          const Text('Keep your spending on track this month', style: TextStyle(color: kMuted, fontSize: 12)),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onViewBudgets,
            child: AppCard(
              child: Column(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: kSoftBlue, color: progress > .9 ? kRed : kGreen),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: Text('${money(spent)} spent', style: const TextStyle(color: kMuted, fontSize: 12))),
                  Text('${money((monthlyBudget - spent).clamp(0, double.infinity))} left', style: const TextStyle(color: kText, fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 25),
          SpendingCategoryChart(transactions: state.thisMonthTransactions),
          const SizedBox(height: 25),
          Row(children: [
            const Expanded(child: Text('Recent transactions', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: kText))),
            TextButton(onPressed: onViewTransactions, child: const Text('View all')),
          ]),
          const SizedBox(height: 5),
          if (recent.isEmpty)
            const EmptyState(icon: Icons.receipt_long_outlined, title: 'No transactions yet', message: 'Tap + to add your first transaction.')
          else
            ...recent.map((t) => TransactionTile(transaction: t, onTap: () => showTransactionDetails(context, state, t))),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add transaction'),
            style: OutlinedButton.styleFrom(foregroundColor: kGreen, side: const BorderSide(color: kGreen), padding: const EdgeInsets.symmetric(vertical: 15)),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.income, required this.expenses, required this.onTap});
  final double balance, income, expenses;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [kGreen, kDarkGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(color: kGreen.withValues(alpha: .18), blurRadius: 20, offset: const Offset(0, 9))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 19),
            const SizedBox(width: 8),
            const Text('Total balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const Spacer(),
            IconButton(onPressed: onTap, visualDensity: VisualDensity.compact, tooltip: 'View transactions', icon: const Icon(Icons.more_horiz, color: Colors.white70)),
          ]),
          const SizedBox(height: 4),
          Text(money(balance), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -.5)),
          const SizedBox(height: 23),
          Container(height: 1, color: Colors.white24),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: _BalanceSummary(label: 'Income this month', amount: money(income, withCurrency: false), icon: Icons.arrow_downward_rounded)),
            Container(height: 40, width: 1, color: Colors.white24),
            const SizedBox(width: 17),
            Expanded(child: _BalanceSummary(label: 'Expenses this month', amount: money(expenses, withCurrency: false), icon: Icons.arrow_upward_rounded)),
          ]),
        ]),
      );
}

class _BalanceSummary extends StatelessWidget {
  const _BalanceSummary({required this.label, required this.amount, required this.icon});
  final String label, amount;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12))),
        ]),
        const SizedBox(height: 7),
        Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
      ]);
}
