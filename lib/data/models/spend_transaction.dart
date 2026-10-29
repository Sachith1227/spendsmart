import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionKind { expense, income, transfer }

class SpendTransaction {
  SpendTransaction({
    String? id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.kind,
    this.notes = '',
    this.paymentMethod = 'Cash',
    this.recurring = false,
    this.recurringSourceId,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final TransactionKind kind;
  final String notes;
  final String paymentMethod;

  /// Whether this transaction repeats every month.
  final bool recurring;

  /// Set on auto-generated copies of a recurring transaction.
  final String? recurringSourceId;

  bool get isIncome => kind == TransactionKind.income;
  bool get isExpense => kind == TransactionKind.expense;
  bool get isTransfer => kind == TransactionKind.transfer;

  SpendTransaction copyWith({
    String? id,
    String? title,
    String? category,
    double? amount,
    DateTime? date,
    TransactionKind? kind,
    String? notes,
    String? paymentMethod,
    bool? recurring,
    String? recurringSourceId,
  }) {
    return SpendTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      kind: kind ?? this.kind,
      notes: notes ?? this.notes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      recurring: recurring ?? this.recurring,
      recurringSourceId: recurringSourceId ?? this.recurringSourceId,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'category': category,
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'kind': kind.name,
        'notes': notes,
        'paymentMethod': paymentMethod,
        'recurring': recurring,
        'recurringSourceId': recurringSourceId,
      };

  factory SpendTransaction.fromMap(String id, Map<String, dynamic> map) => SpendTransaction(
        id: id,
        title: map['title'] as String? ?? '',
        category: map['category'] as String? ?? 'Other',
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        kind: TransactionKind.values.asNameMap()[map['kind']] ?? TransactionKind.expense,
        notes: map['notes'] as String? ?? '',
        paymentMethod: map['paymentMethod'] as String? ?? 'Cash',
        recurring: map['recurring'] as bool? ?? false,
        recurringSourceId: map['recurringSourceId'] as String?,
      );
}
