import 'package:flutter/material.dart';

import '../models/spend_transaction.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import 'add_transaction_screen.dart';

/// Shows details for [transaction] with edit and delete actions.
Future<void> showTransactionDetails(BuildContext context, AppState state, SpendTransaction transaction) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (sheetContext) => _TransactionDetailsSheet(state: state, transaction: transaction, hostContext: context),
  );
}

/// Opens the editor for [transaction] and saves the result.
Future<void> editTransaction(BuildContext context, AppState state, SpendTransaction transaction) async {
  final result = await Navigator.of(context).push<SpendTransaction>(
    MaterialPageRoute(builder: (_) => AddTransactionScreen(initial: transaction)),
  );
  if (result == null || !context.mounted) return;
  state.updateTransaction(result);
  showMessage(context, 'Transaction updated');
}

/// Deletes [transaction] and offers an undo action.
void deleteTransactionWithUndo(BuildContext context, AppState state, SpendTransaction transaction) {
  final removed = state.deleteTransaction(transaction.id);
  if (removed == null) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('"${removed.title}" deleted'),
      action: SnackBarAction(label: 'Undo', onPressed: () => state.restoreTransaction(removed)),
    ));
}

class _TransactionDetailsSheet extends StatelessWidget {
  const _TransactionDetailsSheet({required this.state, required this.transaction, required this.hostContext});
  final AppState state;
  final SpendTransaction transaction;
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final color = t.isIncome ? kGreen : t.isTransfer ? kTransferBlue : kRed;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: kCardBorder, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 18),
          Row(children: [
            CircleAvatar(radius: 24, backgroundColor: color.withValues(alpha: .1), child: Icon(categoryIcon(t.category), color: color)),
            const SizedBox(width: 12),
            Expanded(child: Text(t.title, style: const TextStyle(color: kText, fontSize: 19, fontWeight: FontWeight.w800))),
          ]),
          const SizedBox(height: 16),
          Text('${t.isIncome ? '+' : t.isTransfer ? '' : '−'}${money(t.amount)}', style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          _row('Type', t.kind.name[0].toUpperCase() + t.kind.name.substring(1)),
          _row('Category', t.category),
          _row('Date', '${fullDate(t.date)} · ${timeOfDay(t.date)}'),
          _row('Payment method', t.paymentMethod),
          if (t.recurring) _row('Repeats', 'Monthly'),
          if (t.recurringSourceId != null) _row('Source', 'Auto-created from a recurring transaction'),
          if (t.notes.isNotEmpty) _row('Notes', t.notes),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  deleteTransactionWithUndo(hostContext, state, t);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(foregroundColor: kRed, side: const BorderSide(color: kRed), padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  editTransaction(hostContext, state, t);
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
                style: FilledButton.styleFrom(backgroundColor: kGreen, padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: kMuted, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(color: kText, fontSize: 13, fontWeight: FontWeight.w600))),
        ]),
      );
}
