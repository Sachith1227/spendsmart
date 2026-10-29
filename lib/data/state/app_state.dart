import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:spendsmart/data/models/budget_item.dart';
import 'package:spendsmart/data/models/savings_goal.dart';
import 'package:spendsmart/data/models/spend_transaction.dart';
import 'package:spendsmart/core/theme/app_colors.dart';
import 'package:spendsmart/core/utils/formatters.dart';

class AppNotification {
  const AppNotification({required this.id, required this.title, required this.message, required this.icon, required this.color});
  final String id, title, message;
  final IconData icon;
  final Color color;
}

/// Single source of truth for transactions, budgets and savings goals.
///
/// Data lives in Firestore under `users/{uid}/{transactions,budgets,goals}`.
/// Writes go to Firestore and the snapshot listeners update the local lists
/// (Firestore applies local writes to snapshots immediately, even offline).
class AppState extends ChangeNotifier {
  AppState(this.uid) {
    _subs = [
      _col('transactions').snapshots().listen((snap) {
        _transactions
          ..clear()
          ..addAll(snap.docs.map((d) => SpendTransaction.fromMap(d.id, d.data())));
        _generateRecurring();
        _recalculateBudgets();
        _markLoaded('transactions');
      }, onError: _onError),
      _col('budgets').snapshots().listen((snap) {
        _budgets
          ..clear()
          ..addAll(snap.docs.map((d) => BudgetItem.fromMap(d.id, d.data())));
        _recalculateBudgets();
        _markLoaded('budgets');
      }, onError: _onError),
      _col('goals').snapshots().listen((snap) {
        _goals
          ..clear()
          ..addAll(snap.docs.map((d) => SavingsGoal.fromMap(d.id, d.data())));
        _markLoaded('goals');
      }, onError: _onError),
    ];
  }

  final String uid;
  late final List<StreamSubscription> _subs;
  final Set<String> _loaded = {};

  /// True once all three collections have delivered their first snapshot.
  bool get isLoaded => _loaded.length == 3;
  String? error;

  CollectionReference<Map<String, dynamic>> _col(String name) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection(name);

  void _markLoaded(String name) {
    _loaded.add(name);
    notifyListeners();
  }

  void _onError(Object e) {
    error = 'Could not sync your data: $e';
    debugPrint(error);
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  final List<SpendTransaction> _transactions = [];
  final List<BudgetItem> _budgets = [];
  final List<SavingsGoal> _goals = [];
  final Set<String> _readNotifications = {};
  String userName = 'SpendSmart User';

  List<SpendTransaction> get transactions {
    final list = List<SpendTransaction>.of(_transactions)..sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(list);
  }

  List<BudgetItem> get budgets => List.unmodifiable(_budgets);
  List<SavingsGoal> get goals => List.unmodifiable(_goals);

  // ---------- Totals ----------

  double _sum(Iterable<SpendTransaction> items) => items.fold<double>(0, (s, t) => s + t.amount);

  double get totalIncome => _sum(_transactions.where((t) => t.isIncome));
  double get totalExpenses => _sum(_transactions.where((t) => t.isExpense));
  double get balance => totalIncome - totalExpenses;

  bool _inMonth(DateTime d, DateTime month) => d.year == month.year && d.month == month.month;

  List<SpendTransaction> get thisMonthTransactions {
    final now = DateTime.now();
    return transactions.where((t) => _inMonth(t.date, now)).toList();
  }

  double get monthIncome => _sum(thisMonthTransactions.where((t) => t.isIncome));
  double get monthExpenses => _sum(thisMonthTransactions.where((t) => t.isExpense));
  double get monthlyBudgetLimit => _budgets.fold<double>(0, (s, b) => s + b.limit);

  /// Expense totals for the last [count] months, oldest first.
  List<MapEntry<DateTime, double>> monthlyExpenseHistory({int count = 6}) {
    final now = DateTime.now();
    return List.generate(count, (i) {
      final month = DateTime(now.year, now.month - (count - 1 - i));
      return MapEntry(month, _sum(_transactions.where((t) => t.isExpense && _inMonth(t.date, month))));
    });
  }

  // ---------- Transactions ----------

  void addTransaction(SpendTransaction t) => _col('transactions').doc(t.id).set(t.toMap());

  void updateTransaction(SpendTransaction updated) {
    final index = _transactions.indexWhere((t) => t.id == updated.id);
    if (index == -1) return;
    final wasRecurring = _transactions[index].recurring;
    final batch = FirebaseFirestore.instance.batch()..set(_col('transactions').doc(updated.id), updated.toMap());
    if (wasRecurring && !updated.recurring) {
      for (final t in _transactions.where((t) => t.recurringSourceId == updated.id && t.date.isAfter(DateTime.now()))) {
        batch.delete(_col('transactions').doc(t.id));
      }
    }
    batch.commit();
  }

  /// Removes a transaction and returns it so the caller can offer undo.
  SpendTransaction? deleteTransaction(String id) {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index == -1) return null;
    final removed = _transactions[index];
    _col('transactions').doc(id).delete();
    return removed;
  }

  void restoreTransaction(SpendTransaction t) {
    if (_transactions.any((e) => e.id == t.id)) return;
    addTransaction(t);
  }

  /// Creates monthly copies of recurring transactions up to today.
  void _generateRecurring() {
    final now = DateTime.now();
    final sources = _transactions.where((t) => t.recurring && t.recurringSourceId == null).toList();
    for (final source in sources) {
      var monthOffset = 1;
      while (true) {
        final lastDay = DateTime(source.date.year, source.date.month + monthOffset + 1, 0).day;
        final day = source.date.day > lastDay ? lastDay : source.date.day;
        final next = DateTime(source.date.year, source.date.month + monthOffset, day, source.date.hour, source.date.minute);
        if (next.isAfter(now)) break;
        final exists = _transactions.any((t) => t.recurringSourceId == source.id && _inMonth(t.date, next));
        if (!exists) {
          final copy = source.copyWith(
            id: '${source.id}-${next.year}-${next.month}',
            date: next,
            recurring: false,
            recurringSourceId: source.id,
          );
          _transactions.add(copy);
          // Deterministic id, so repeated runs (or other devices) never duplicate.
          _col('transactions').doc(copy.id).set(copy.toMap());
        }
        monthOffset++;
      }
    }
  }

  // ---------- Budgets ----------

  void _recalculateBudgets() {
    for (final b in _budgets) {
      b.spent = 0;
    }
    for (final t in thisMonthTransactions.where((t) => t.isExpense)) {
      final category = budgetCategoryFor(t.category);
      for (final b in _budgets.where((b) => b.category == category)) {
        b.spent += t.amount;
      }
    }
  }

  void addBudget(BudgetItem budget) => _col('budgets').doc(budget.id).set(budget.toMap());

  void updateBudgetLimit(BudgetItem budget, double limit) => _col('budgets').doc(budget.id).update({'limit': limit});

  void deleteBudget(BudgetItem budget) => _col('budgets').doc(budget.id).delete();

  // ---------- Savings goals ----------

  void addGoal(SavingsGoal goal) => _col('goals').doc(goal.id).set(goal.toMap());

  void contributeToGoal(SavingsGoal goal, double amount) {
    // Update locally too so callers can read the new value right away.
    goal.saved = (goal.saved + amount).clamp(0.0, double.infinity).toDouble();
    _col('goals').doc(goal.id).update({'saved': goal.saved});
  }

  void deleteGoal(SavingsGoal goal) => _col('goals').doc(goal.id).delete();

  // ---------- Profile ----------

  void updateUserName(String name) {
    userName = name;
    notifyListeners();
  }

  // ---------- Notifications ----------

  List<AppNotification> get notifications {
    final items = <AppNotification>[];
    for (final b in _budgets) {
      if (b.usedRatio >= 1) {
        items.add(AppNotification(id: 'over-${b.name}-${b.spent.round()}', title: '${b.name} over budget', message: 'You have spent ${money(b.spent)} of ${money(b.limit)} this month.', icon: Icons.error_outline, color: kRed));
      } else if (b.usedRatio >= .9) {
        items.add(AppNotification(id: 'near-${b.name}-${b.spent.round()}', title: '${b.name} near limit', message: 'Only ${money(b.remaining)} left this month.', icon: Icons.warning_amber_rounded, color: kRed));
      }
    }
    for (final g in _goals.where((g) => g.isComplete)) {
      items.add(AppNotification(id: 'goal-${g.title}', title: 'Goal reached: ${g.title}', message: 'You saved ${money(g.saved)}. Great job!', icon: Icons.celebration_outlined, color: kGreen));
    }
    if (monthExpenses > monthIncome && monthIncome > 0) {
      items.add(AppNotification(id: 'cashflow-${DateTime.now().month}', title: 'Spending exceeds income', message: 'This month you spent ${money(monthExpenses - monthIncome)} more than you earned.', icon: Icons.trending_down, color: kRed));
    }
    return items;
  }

  int get unreadNotificationCount => notifications.where((n) => !_readNotifications.contains(n.id)).length;

  void markNotificationsRead() {
    _readNotifications.addAll(notifications.map((n) => n.id));
    notifyListeners();
  }

  // ---------- Export ----------

  String exportCsv(List<SpendTransaction> items) {
    final buffer = StringBuffer('Date,Time,Title,Category,Type,Amount (LKR),Payment method,Notes\n');
    for (final t in items) {
      buffer.writeln([
        '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}',
        timeOfDay(t.date),
        csvEscape(t.title),
        csvEscape(t.category),
        t.kind.name,
        t.amount.toStringAsFixed(2),
        csvEscape(t.paymentMethod),
        csvEscape(t.notes),
      ].join(','));
    }
    return buffer.toString();
  }
}
