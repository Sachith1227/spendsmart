import 'package:flutter/material.dart';

import '../models/spend_transaction.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction, this.onTap});
  final SpendTransaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;
    final color = isIncome ? kGreen : transaction.isTransfer ? kTransferBlue : kRed;
    final sign = isIncome ? '+' : transaction.isTransfer ? '' : '−';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(19), border: Border.all(color: kCardBorder)),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: isIncome ? const Color(0xFFDDF7E6) : const Color(0xFFFFF0E2), borderRadius: BorderRadius.circular(14)),
                child: Icon(categoryIcon(transaction.category), color: color, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Text(transaction.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: kText))),
                    if (transaction.recurring || transaction.recurringSourceId != null) ...[
                      const SizedBox(width: 5),
                      const Icon(Icons.repeat, size: 14, color: kMuted),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Text('${transaction.category} · ${shortDate(transaction.date)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 11)),
                  if (transaction.paymentMethod.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(transaction.paymentMethod, style: const TextStyle(color: kMuted, fontSize: 10)),
                  ],
                ]),
              ),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('$sign${money(transaction.amount)}', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
                const SizedBox(height: 5),
                Text(timeOfDay(transaction.date), style: const TextStyle(color: kMuted, fontSize: 11)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
