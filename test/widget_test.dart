import 'package:flutter_test/flutter_test.dart';

import 'package:spendsmart/data/models/budget_item.dart';
import 'package:spendsmart/data/models/savings_goal.dart';
import 'package:spendsmart/data/models/spend_transaction.dart';

// The full app needs Firebase, so these tests cover the Firestore mapping only.
void main() {
  test('Transaction survives a Firestore round trip', () {
    final t = SpendTransaction(title: 'Groceries', category: 'Food & Dining', amount: 1500, date: DateTime(2026, 1, 5, 10), kind: TransactionKind.expense, recurring: true);
    final copy = SpendTransaction.fromMap(t.id, t.toMap());
    expect(copy.title, t.title);
    expect(copy.amount, t.amount);
    expect(copy.date, t.date);
    expect(copy.kind, t.kind);
    expect(copy.recurring, isTrue);
  });

  test('Budget and goal survive a Firestore round trip', () {
    final b = BudgetItem.fromMap('b1', {'name': 'Food', 'category': 'Food & Groceries', 'limit': 40000});
    expect(b.toMap(), {'name': 'Food', 'category': 'Food & Groceries', 'limit': 40000.0});

    final g = SavingsGoal(title: 'Laptop', target: 200000, saved: 5000, icon: kGoalIcons[2]);
    final copy = SavingsGoal.fromMap(g.id, g.toMap());
    expect(copy.icon, kGoalIcons[2]);
    expect(copy.saved, 5000);
  });
}
