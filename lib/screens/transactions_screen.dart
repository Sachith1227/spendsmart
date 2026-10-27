import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/spend_transaction.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_details_sheet.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key, required this.state, required this.onAdd});
  final AppState state;
  final VoidCallback onAdd;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _search = TextEditingController();
  String _filter = 'All';
  String _sort = 'Newest first';
  DateTimeRange? _range;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<SpendTransaction> get _filtered {
    final query = _search.text.trim().toLowerCase();
    final items = widget.state.transactions.where((t) {
      final matchesQuery = query.isEmpty ||
          t.title.toLowerCase().contains(query) ||
          t.category.toLowerCase().contains(query) ||
          t.notes.toLowerCase().contains(query) ||
          t.paymentMethod.toLowerCase().contains(query);
      final matchesFilter = _filter == 'All' ||
          (_filter == 'Expenses' && t.isExpense) ||
          (_filter == 'Income' && t.isIncome) ||
          (_filter == 'Transfers' && t.isTransfer);
      final matchesRange = _range == null ||
          (!t.date.isBefore(_range!.start) && t.date.isBefore(_range!.end.add(const Duration(days: 1))));
      return matchesQuery && matchesFilter && matchesRange;
    }).toList();
    switch (_sort) {
      case 'Oldest first':
        items.sort((a, b) => a.date.compareTo(b.date));
      case 'Highest amount':
        items.sort((a, b) => b.amount.compareTo(a.amount));
      case 'Lowest amount':
        items.sort((a, b) => a.amount.compareTo(b.amount));
      default:
        items.sort((a, b) => b.date.compareTo(a.date));
    }
    return items;
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  Future<void> _export(List<SpendTransaction> items) async {
    if (items.isEmpty) {
      showMessage(context, 'No transactions to export.');
      return;
    }
    final csv = widget.state.exportCsv(items);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Export CSV'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${items.length} transactions ready to export.', style: const TextStyle(color: kMuted)),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: kBackground, borderRadius: BorderRadius.circular(12)),
              child: SingleChildScrollView(child: SelectableText(csv, style: const TextStyle(fontFamily: 'monospace', fontSize: 11))),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: csv));
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (!mounted) return;
              showMessage(context, 'CSV copied to clipboard');
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final totalExpense = items.where((t) => t.isExpense).fold<double>(0, (s, t) => s + t.amount);
    final totalIncome = items.where((t) => t.isIncome).fold<double>(0, (s, t) => s + t.amount);

    return SafeArea(
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 110), children: [
        Row(children: [
          const Expanded(child: Text('Transactions', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kText))),
          IconButton(onPressed: () => _export(items), icon: const Icon(Icons.ios_share_outlined), tooltip: 'Export CSV'),
        ]),
        const SizedBox(height: 15),
        AppCard(
          child: Column(children: [
            Row(children: [
              Expanded(child: _MiniMetric(label: 'Income', value: money(totalIncome, withCurrency: false), color: kGreen)),
              const SizedBox(width: 12),
              Expanded(child: _MiniMetric(label: 'Expenses', value: money(totalExpense, withCurrency: false), color: kRed)),
            ]),
            const SizedBox(height: 14),
            Text('Totals for the ${items.length} transactions shown below.', style: const TextStyle(fontSize: 11, color: kMuted)),
          ]),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Search merchant, category, notes...',
            isDense: true,
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(icon: const Icon(Icons.close), onPressed: () => setState(_search.clear)),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final f in ['All', 'Expenses', 'Income', 'Transfers'])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f),
                  selected: _filter == f,
                  onSelected: (_) => setState(() => _filter = f),
                  selectedColor: kGreen,
                  showCheckmark: false,
                  labelStyle: TextStyle(color: _filter == f ? Colors.white : kText, fontWeight: FontWeight.w600),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: _filter == f ? kGreen : kCardBorder),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: InkWell(
              onTap: _pickRange,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  const Icon(Icons.calendar_month_outlined, color: kGreen, size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _range == null ? 'All dates' : '${fullDate(_range!.start)} – ${fullDate(_range!.end)}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: kMuted, fontSize: 13),
                    ),
                  ),
                  if (_range != null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => setState(() => _range = null),
                    ),
                ]),
              ),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sort,
              items: const ['Newest first', 'Oldest first', 'Highest amount', 'Lowest amount']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s, style: TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) => setState(() => _sort = v ?? 'Newest first'),
            ),
          ),
        ]),
        const SizedBox(height: 4),
        const Text('Tap a transaction to edit, swipe left to delete.', style: TextStyle(color: kMuted, fontSize: 11)),
        const SizedBox(height: 10),
        if (items.isEmpty)
          const EmptyState(icon: Icons.search_off, title: 'No transactions found', message: 'Try another search, filter or date range.')
        else
          ...items.map((t) => Dismissible(
                key: ValueKey(t.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.only(right: 22),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(19)),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) => deleteTransactionWithUndo(context, widget.state, t),
                child: TransactionTile(transaction: t, onTap: () => showTransactionDetails(context, widget.state, t)),
              )),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: widget.onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add transaction'),
          style: FilledButton.styleFrom(backgroundColor: kGreen, padding: const EdgeInsets.symmetric(vertical: 15)),
        ),
      ]),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: kBackground, borderRadius: BorderRadius.circular(15)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: kMuted, fontSize: 12)),
          const SizedBox(height: 5),
          FittedBox(fit: BoxFit.scaleDown, child: Text('LKR $value', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800))),
        ]),
      );
}
