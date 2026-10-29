import 'package:flutter/material.dart';

import 'package:spendsmart/data/models/spend_transaction.dart';
import 'package:spendsmart/core/theme/app_colors.dart';
import 'package:spendsmart/core/utils/formatters.dart';
import 'package:spendsmart/core/widgets/common.dart';

class SpendingCategoryChart extends StatelessWidget {
  const SpendingCategoryChart({super.key, required this.transactions});

  final List<SpendTransaction> transactions;

  static const List<Color> palette = [
    Color(0xFF087A35),
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
    Color(0xFF64748B),
  ];

  @override
  Widget build(BuildContext context) {
    final totals = <String, double>{};
    for (final t in transactions.where((t) => t.isExpense)) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
    }
    final entries = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<double>(0, (sum, e) => sum + e.value);
    final shown = entries.length > 5 ? 5 : entries.length;

    return AppCard(
      padding: const EdgeInsets.all(18),
      radius: 22,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Spending by category', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: kText)),
        const SizedBox(height: 4),
        const Text('See which categories use most of your money', style: TextStyle(color: kMuted, fontSize: 12)),
        const SizedBox(height: 18),
        if (total <= 0)
          const EmptyState(icon: Icons.pie_chart_outline, title: 'No spending yet', message: 'Add an expense to see your category breakdown.')
        else ...[
          SizedBox(
            height: 190,
            child: Row(children: [
              Expanded(
                flex: 5,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CustomPaint(
                      painter: PieChartPainter(
                        values: entries.map((e) => e.value).toList(),
                        colors: List.generate(entries.length, (i) => palette[i % palette.length]),
                      ),
                      child: Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Text('TOTAL SPENT', style: TextStyle(color: kMuted, fontSize: 9, letterSpacing: .7, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          FittedBox(child: Text(money(total), style: const TextStyle(color: kText, fontSize: 17, fontWeight: FontWeight.w800))),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < shown; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(top: 3),
                            decoration: BoxDecoration(color: palette[i % palette.length], borderRadius: BorderRadius.circular(3)),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(entries[i].key, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kText, fontSize: 10, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text('${(entries[i].value / total * 100).round()}% · ${money(entries[i].value)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 9)),
                            ]),
                          ),
                        ]),
                      ),
                  ],
                ),
              ),
            ]),
          ),
          if (entries.length > 5) ...[
            const SizedBox(height: 5),
            Text('+ ${entries.length - 5} more categories included in the chart', style: const TextStyle(color: kMuted, fontSize: 10)),
          ],
        ],
      ]),
    );
  }
}

class PieChartPainter extends CustomPainter {
  const PieChartPainter({required this.values, required this.colors});

  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, v) => sum + v);
    if (total <= 0) return;

    final rect = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    var startAngle = -1.5707963267948966;
    for (var i = 0; i < values.length; i++) {
      final sweepAngle = values[i] / total * 6.283185307179586;
      canvas.drawArc(rect, startAngle, sweepAngle, true, Paint()..color = colors[i % colors.length]);
      startAngle += sweepAngle;
    }
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width * .255, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) => oldDelegate.values != values || oldDelegate.colors != colors;
}
