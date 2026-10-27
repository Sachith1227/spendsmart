import 'package:flutter/material.dart';

import '../models/spend_transaction.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

/// Adds a new transaction, or edits [initial] when provided.
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, this.initial});
  final SpendTransaction? initial;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amount = TextEditingController();
  final _description = TextEditingController();
  final _notes = TextEditingController();
  TransactionKind _kind = TransactionKind.expense;
  String _category = 'Food & Dining';
  String _payment = 'Cash';
  DateTime _date = DateTime.now();
  bool _recurring = false;

  static const _expenseCategories = [
    ('Food & Dining', Icons.restaurant_outlined),
    ('Transport', Icons.directions_car_outlined),
    ('Utilities & Bills', Icons.bolt_outlined),
    ('Shopping', Icons.shopping_bag_outlined),
    ('Education', Icons.school_outlined),
    ('Health', Icons.medical_services_outlined),
    ('Other', Icons.category_outlined),
  ];
  static const _incomeCategories = [
    ('Salary', Icons.account_balance_outlined),
    ('Allowance', Icons.wallet_outlined),
    ('Freelance', Icons.laptop_outlined),
    ('Gift', Icons.card_giftcard_outlined),
    ('Other', Icons.category_outlined),
  ];
  static const _transferCategories = [
    ('Transfer', Icons.swap_horiz_rounded),
    ('Savings', Icons.savings_outlined),
    ('Other', Icons.category_outlined),
  ];
  static const _paymentMethods = ['Cash', 'Commercial Bank', 'Card', 'Online Banking', 'Bank Transfer'];

  bool get _isEditing => widget.initial != null;

  List<(String, IconData)> get _categories => switch (_kind) {
        TransactionKind.expense => _expenseCategories,
        TransactionKind.income => _incomeCategories,
        TransactionKind.transfer => _transferCategories,
      };

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    if (t != null) {
      _amount.text = t.amount == t.amount.roundToDouble() ? t.amount.toStringAsFixed(0) : t.amount.toString();
      _description.text = t.title;
      _notes.text = t.notes;
      _kind = t.kind;
      _category = t.category;
      _payment = _paymentMethods.contains(t.paymentMethod) ? t.paymentMethod : 'Cash';
      _date = t.date;
      _recurring = t.recurring;
      if (!_categories.any((c) => c.$1 == _category)) _category = 'Other';
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _setKind(TransactionKind kind) {
    setState(() {
      _kind = kind;
      if (!_categories.any((c) => c.$1 == _category)) _category = _categories.first.$1;
    });
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (selected == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date));
    setState(() => _date = DateTime(selected.year, selected.month, selected.day, time?.hour ?? _date.hour, time?.minute ?? _date.minute));
  }

  void _save() {
    final amount = double.tryParse(_amount.text.replaceAll(',', '').trim());
    final description = _description.text.trim();
    if (amount == null || amount <= 0) {
      showMessage(context, 'Enter an amount greater than zero.');
      return;
    }
    if (description.isEmpty) {
      showMessage(context, 'Enter a description or merchant.');
      return;
    }
    final base = widget.initial;
    final transaction = SpendTransaction(
      id: base?.id,
      title: description,
      category: _category,
      amount: amount,
      date: _date,
      kind: _kind,
      notes: _notes.text.trim(),
      paymentMethod: _payment,
      recurring: base?.recurringSourceId == null && _recurring,
      recurringSourceId: base?.recurringSourceId,
    );
    Navigator.pop(context, transaction);
  }

  void _addQuickAmount(int value) {
    final current = double.tryParse(_amount.text.replaceAll(',', '')) ?? 0;
    setState(() => _amount.text = (current + value).toStringAsFixed(0));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
          title: Text(_isEditing ? 'Edit transaction' : 'Quick Add', style: const TextStyle(fontWeight: FontWeight.w800)),
          actions: [TextButton(onPressed: _save, child: const Text('Save'))],
        ),
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 28), children: [
            AppCard(
              padding: const EdgeInsets.all(18),
              radius: 23,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(_isEditing ? 'Update details' : 'Add transaction', style: const TextStyle(color: kText, fontSize: 21, fontWeight: FontWeight.w800))),
                  Container(padding: const EdgeInsets.all(9), decoration: const BoxDecoration(color: kSoftBlue, shape: BoxShape.circle), child: const Icon(Icons.edit_note, color: kGreen)),
                ]),
                const SizedBox(height: 17),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<TransactionKind>(
                    segments: const [
                      ButtonSegment(value: TransactionKind.expense, label: Text('Expense'), icon: Icon(Icons.arrow_upward)),
                      ButtonSegment(value: TransactionKind.income, label: Text('Income'), icon: Icon(Icons.arrow_downward)),
                      ButtonSegment(value: TransactionKind.transfer, label: Text('Transfer'), icon: Icon(Icons.swap_horiz)),
                    ],
                    selected: {_kind},
                    onSelectionChanged: (s) => _setKind(s.first),
                    style: SegmentedButton.styleFrom(selectedBackgroundColor: kGreen, selectedForegroundColor: Colors.white, visualDensity: VisualDensity.compact),
                  ),
                ),
                const SizedBox(height: 20),
                _buildAmountCard(),
                const SizedBox(height: 20),
                const _FormSectionLabel('Description & merchant', trailing: 'Required'),
                const SizedBox(height: 8),
                TextField(controller: _description, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'e.g. Keells Supermarket')),
                const SizedBox(height: 17),
                const _FormSectionLabel('Category'),
                const SizedBox(height: 10),
                _buildCategoryGrid(),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: _DatePickerCard(date: _date, onTap: _pickDate)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildPaymentPicker()),
                ]),
                const SizedBox(height: 18),
                if (widget.initial?.recurringSourceId == null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(color: kBackground, borderRadius: BorderRadius.circular(16)),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _recurring,
                      onChanged: (v) => setState(() => _recurring = v),
                      activeThumbColor: kGreen,
                      title: const Text('Recurring transaction', style: TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w700)),
                      subtitle: const Text('Repeat this transaction monthly', style: TextStyle(color: kMuted, fontSize: 11)),
                    ),
                  ),
                if (_recurring)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('A copy will be added automatically on this day every month.', style: TextStyle(color: kMuted, fontSize: 11)),
                  ),
                const SizedBox(height: 18),
                const _FormSectionLabel('Notes', trailing: 'Optional'),
                const SizedBox(height: 8),
                TextField(controller: _notes, maxLines: 3, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'Add details about this transaction...')),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(_isEditing ? 'Save changes' : 'Save transaction'),
                    style: FilledButton.styleFrom(backgroundColor: kGreen, padding: const EdgeInsets.symmetric(vertical: 17), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  ),
                ),
                const SizedBox(height: 5),
                SizedBox(width: double.infinity, child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: kMuted)))),
              ]),
            ),
          ]),
        ),
      );

  Widget _buildAmountCard() => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(color: kBackground, borderRadius: BorderRadius.circular(19)),
        child: Column(children: [
          const Text('AMOUNT IN SRI LANKAN RUPEE', style: TextStyle(color: kMuted, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              _kind == TransactionKind.expense ? '− LKR' : _kind == TransactionKind.income ? '+ LKR' : 'LKR',
              style: TextStyle(color: _kind == TransactionKind.income ? kGreen : kMuted, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: TextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: const TextStyle(color: kText, fontSize: 31, fontWeight: FontWeight.w800),
                decoration: const InputDecoration(hintText: '0.00', filled: false, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, contentPadding: EdgeInsets.zero),
              ),
            ),
          ]),
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            alignment: WrapAlignment.center,
            children: [500, 1000, 5000, 10000]
                .map((v) => ActionChip(label: Text('+$v'), onPressed: () => _addQuickAmount(v), backgroundColor: kSoftBlue, side: BorderSide.none, labelStyle: const TextStyle(fontSize: 11, color: kText)))
                .toList(),
          ),
        ]),
      );

  Widget _buildCategoryGrid() => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: .86),
        itemBuilder: (context, index) {
          final item = _categories[index];
          final selected = _category == item.$1;
          return InkWell(
            onTap: () => setState(() => _category = item.$1),
            borderRadius: BorderRadius.circular(15),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFDDF7E6) : kBackground,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: selected ? kGreen : kCardBorder, width: selected ? 1.5 : 1),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(item.$2, color: selected ? kGreen : kMuted, size: 24),
                const SizedBox(height: 7),
                Text(item.$1, textAlign: TextAlign.center, maxLines: 2, style: TextStyle(fontSize: 10, color: selected ? kGreen : kText, fontWeight: selected ? FontWeight.w800 : FontWeight.w500)),
              ]),
            ),
          );
        },
      );

  Widget _buildPaymentPicker() => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: kBackground, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Payment method', style: TextStyle(color: kMuted, fontSize: 11)),
          const SizedBox(height: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              isDense: true,
              value: _payment,
              items: _paymentMethods.map((p) => DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)))).toList(),
              onChanged: (v) => setState(() => _payment = v ?? _payment),
            ),
          ),
        ]),
      );
}

class _FormSectionLabel extends StatelessWidget {
  const _FormSectionLabel(this.title, {this.trailing});
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Text(title, style: const TextStyle(color: kText, fontWeight: FontWeight.w700, fontSize: 13))),
        if (trailing != null) Text(trailing!, style: const TextStyle(color: kMuted, fontSize: 11)),
      ]);
}

class _DatePickerCard extends StatelessWidget {
  const _DatePickerCard({required this.date, required this.onTap});
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(color: kBackground, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Date & time', style: TextStyle(color: kMuted, fontSize: 11)),
            const SizedBox(height: 9),
            Row(children: [
              const Icon(Icons.calendar_today_outlined, color: kGreen, size: 17),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: kText, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ]),
        ),
      );
}
