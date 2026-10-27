import 'package:flutter/material.dart';

import '../models/budget_item.dart';
import '../models/savings_goal.dart';
import '../models/spend_transaction.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

class AppNotification {
  const AppNotification({required this.id, required this.title, required this.message, required this.icon, required this.color});
  final String id, title, message;
  final IconData icon;
  final Color color;
}

/// Single source of truth for transactions, budgets and savings goals.
class AppState extends ChangeNotifier {
  AppState() {
    _seed();
    _generateRecurring();
    _recalculateBudgets();
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

  void addTransaction(SpendTransaction t) {
    _transactions.add(t);
    _generateRecurring();
    _recalculateBudgets();
    notifyListeners();
  }

  void updateTransaction(SpendTransaction updated) {
    final index = _transactions.indexWhere((t) => t.id == updated.id);
    if (index == -1) return;
    final wasRecurring = _transactions[index].recurring;
    _transactions[index] = updated;
    if (wasRecurring && !updated.recurring) {
      _transactions.removeWhere((t) => t.recurringSourceId == updated.id && t.date.isAfter(DateTime.now()));
    }
    _generateRecurring();
    _recalculateBudgets();
    notifyListeners();
  }

  /// Removes a transaction and returns it so the caller can offer undo.
  SpendTransaction? deleteTransaction(String id) {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index == -1) return null;
    final removed = _transactions.removeAt(index);
    _recalculateBudgets();
    notifyListeners();
    return removed;
  }

  void restoreTransaction(SpendTransaction t) {
    if (_transactions.any((e) => e.id == t.id)) return;
    _transactions.add(t);
    _recalculateBudgets();
    notifyListeners();
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
          _transactions.add(source.copyWith(
            id: '${source.id}-${next.year}-${next.month}',
            date: next,
            recurring: false,
            recurringSourceId: source.id,
          ));
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

  void addBudget(BudgetItem budget) {
    _budgets.add(budget);
    _recalculateBudgets();
    notifyListeners();
  }

  void updateBudgetLimit(BudgetItem budget, double limit) {
    budget.limit = limit;
    notifyListeners();
  }

  void deleteBudget(BudgetItem budget) {
    _budgets.remove(budget);
    notifyListeners();
  }

  // ---------- Savings goals ----------

  void addGoal(SavingsGoal goal) {
    _goals.add(goal);
    notifyListeners();
  }

  void contributeToGoal(SavingsGoal goal, double amount) {
    goal.saved = (goal.saved + amount).clamp(0.0, double.infinity).toDouble();
    notifyListeners();
  }

  void deleteGoal(SavingsGoal goal) {
    _goals.remove(goal);
    notifyListeners();
  }

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

  // ---------- Sample data ----------

  void _seed() {
    final now = DateTime.now();
    DateTime daysAgo(int d, [int hour = 10]) => DateTime(now.year, now.month, now.day - d, hour, 15);

    _transactions.addAll([
      SpendTransaction(id: 's1', title: 'Monthly salary', category: 'Salary', amount: 60000, date: DateTime(now.year, now.month, 1, 9), kind: TransactionKind.income, paymentMethod: 'Bank Transfer', recurring: true),
      SpendTransaction(id: 's2', title: 'Groceries', category: 'Food & Dining', amount: 1500, date: daysAgo(0, 18), kind: TransactionKind.expense, paymentMethod: 'Commercial Bank'),
      SpendTransaction(id: 's3', title: 'Bus fare', category: 'Transport', amount: 750, date: daysAgo(2, 8), kind: TransactionKind.expense),
      SpendTransaction(id: 's4', title: 'Internet bill', category: 'Utilities & Bills', amount: 3890, date: daysAgo(3), kind: TransactionKind.expense, paymentMethod: 'Online Banking'),
      SpendTransaction(id: 's5', title: 'Online course', category: 'Education', amount: 4500, date: daysAgo(5), kind: TransactionKind.expense, paymentMethod: 'Card'),
      SpendTransaction(id: 's6', title: 'Savings transfer', category: 'Transfer', amount: 5000, date: daysAgo(6), kind: TransactionKind.transfer, paymentMethod: 'Bank Transfer'),
      SpendTransaction(id: 's7', title: 'Last month groceries', category: 'Food & Dining', amount: 12000, date: DateTime(now.year, now.month - 1, 12, 17), kind: TransactionKind.expense),
      SpendTransaction(id: 's8', title: 'Last month fuel', category: 'Transport', amount: 6500, date: DateTime(now.year, now.month - 1, 18, 7), kind: TransactionKind.expense),
    ]);

    _budgets.addAll([
      BudgetItem(name: 'Food & Groceries', category: 'Food & Groceries', limit: 40000, icon: Icons.shopping_cart_outlined, color: const Color(0xFF64796A)),
      BudgetItem(name: 'Transport & Fuel', category: 'Transport & Fuel', limit: 25000, icon: Icons.directions_bus_outlined, color: kGreen),
      BudgetItem(name: 'Utilities & Bills', category: 'Utilities & Bills', limit: 4000, icon: Icons.bolt_outlined, color: kRed),
      BudgetItem(name: 'Shopping & Lifestyle', category: 'Shopping & Lifestyle', limit: 20000, icon: Icons.shopping_bag_outlined, color: const Color(0xFF397653)),
      BudgetItem(name: 'Education & Courses', category: 'Education & Courses', limit: 30000, icon: Icons.school_outlined, color: const Color(0xFF397653)),
    ]);

    _goals.addAll([
      SavingsGoal(title: 'Emergency fund', saved: 75000, target: 150000, icon: Icons.shield_outlined),
      SavingsGoal(title: 'New laptop', saved: 90000, target: 200000, icon: Icons.laptop_mac_outlined),
      SavingsGoal(title: 'Holiday', saved: 25000, target: 100000, icon: Icons.flight_takeoff_outlined),
    ]);
  }
}
