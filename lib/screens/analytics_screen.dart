import 'package:flutter/material.dart';

import '../models/spend_transaction.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key, required this.state});
  final AppState state;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _thisMonthOnly = true;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final List<SpendTransaction> source = _thisMonthOnly ? state.thisMonthTransactions : state.transactions;
    final income = source.where((t) => t.isIncome).fold<double>(0, (s, t) => s + t.amount);
    final expenses = source.where((t) => t.isExpense).fold<double>(0, (s, t) => s + t.amount);
    final savingsRate = income <= 0 ? 0.0 : ((income - expenses) / income).clamp(-1.0, 1.0);

    final byCategory = <String, double>{};
    for (final t in source.where((t) => t.isExpense)) {
      byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
    }
    final categories = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxValue = categories.isEmpty ? 1.0 : categories.first.value;
    final history = state.monthlyExpenseHistory();

    return SafeArea(
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 110), children: [
        const Text('Analytics', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kText)),
        const SizedBox(height: 5),
        const Text('Understand where your money goes.', style: TextStyle(color: kMuted)),
        const SizedBox(height: 16),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('This month')),
            ButtonSegment(value: false, label: Text('All time')),
          ],
          selected: {_thisMonthOnly},
          onSelectionChanged: (s) => setState(() => _thisMonthOnly = s.first),
          style: SegmentedButton.styleFrom(selectedBackgroundColor: kGreen, selectedForegroundColor: Colors.white),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _AnalyticsMetric(label: 'Income', value: money(income), icon: Icons.south_west, color: kGreen)),
          const SizedBox(width: 12),
          Expanded(child: _AnalyticsMetric(label: 'Expenses', value: money(expenses), icon: Icons.north_east, color: kRed)),
        ]),
        const SizedBox(height: 12),
        _AnalyticsMetric(
          label: 'Savings rate',
          value: '${(savingsRate * 100).round()}%  ·  ${money(income - expenses)} net',
          icon: Icons.savings_outlined,
          color: savingsRate >= 0 ? kGreen : kRed,
        ),
        const SizedBox(height: 18),
        _MonthlyTrend(history: history),
        const SizedBox(height: 18),
        AppCard(
          padding: const EdgeInsets.all(19),
          radius: 22,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Spending by category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kText)),
            const SizedBox(height: 5),
            Text(_thisMonthOnly ? 'Expenses recorded this month' : 'All recorded expenses', style: const TextStyle(fontSize: 11, color: kMuted)),
            const SizedBox(height: 22),
            if (categories.isEmpty)
              const Text('Add expenses to see your category breakdown.', style: TextStyle(color: kMuted))
            else
              ...categories.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(children: [
                      Row(children: [
                        Icon(categoryIcon(e.key), color: kGreen, size: 19),
                        const SizedBox(width: 8),
                        Expanded(child: Text(e.key, style: const TextStyle(color: kText, fontWeight: FontWeight.w600))),
                        Text('${money(e.value)} · ${(e.value / expenses * 100).round()}%', style: const TextStyle(color: kText, fontWeight: FontWeight.w700, fontSize: 12)),
                      ]),
                      const SizedBox(height: 9),
                      ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: e.value / maxValue, minHeight: 9, color: kGreen, backgroundColor: kSoftBlue)),
                    ]),
                  )),
          ]),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(22)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.lightbulb_outline, color: Color(0xFFBDF8D0), size: 27),
            const SizedBox(height: 10),
            const Text('Smart tip', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text(_tip(income, expenses, categories), style: const TextStyle(color: Colors.white, height: 1.45)),
          ]),
        ),
      ]),
    );
  }

  String _tip(double income, double expenses, List<MapEntry<String, double>> categories) {
    if (income == 0 && expenses == 0) return 'Start adding transactions to get personalised tips.';
    if (expenses > income) {
      return 'Your expenses are higher than your income. Review your budget categories to find places to save.';
    }
    if (categories.isNotEmpty && expenses > 0 && categories.first.value / expenses > .4) {
      return '${categories.first.key} makes up ${(categories.first.value / expenses * 100).round()}% of your spending. Small cuts there will have the biggest impact.';
    }
    return 'Great work! You are spending less than you earn. Consider moving the difference into a savings goal.';
  }
}

class _MonthlyTrend extends StatelessWidget {
  const _MonthlyTrend({required this.history});
  final List<MapEntry<DateTime, double>> history;

  @override
  Widget build(BuildContext context) {
    final maxValue = history.fold<double>(0, (m, e) => e.value > m ? e.value : m);
    return AppCard(
      padding: const EdgeInsets.all(19),
      radius: 22,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Monthly spending', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kText)),
        const SizedBox(height: 5),
        const Text('Expenses over the last 6 months', style: TextStyle(fontSize: 11, color: kMuted)),
        const SizedBox(height: 18),
        SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: history.map((e) {
              final ratio = maxValue <= 0 ? 0.0 : e.value / maxValue;
              final isCurrent = e == history.last;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    FittedBox(child: Text(e.value == 0 ? '' : '${(e.value / 1000).toStringAsFixed(1)}k', style: const TextStyle(color: kMuted, fontSize: 10))),
                    const SizedBox(height: 4),
                    Flexible(
                      child: FractionallySizedBox(
                        heightFactor: ratio == 0 ? .02 : ratio,
                        child: Container(decoration: BoxDecoration(color: isCurrent ? kGreen : kSoftBlue, borderRadius: BorderRadius.circular(8))),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(kMonths[e.key.month - 1], style: TextStyle(color: isCurrent ? kGreen : kMuted, fontSize: 11, fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500)),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }
}

class _AnalyticsMetric extends StatelessWidget {
  const _AnalyticsMetric({required this.label, required this.value, required this.icon, required this.color});
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(15),
        radius: 18,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: kMuted, fontSize: 12)),
          const SizedBox(height: 4),
          FittedBox(alignment: Alignment.centerLeft, fit: BoxFit.scaleDown, child: Text(value, style: TextStyle(color: color, fontSize: 19, fontWeight: FontWeight.w800))),
        ]),
      );
}
