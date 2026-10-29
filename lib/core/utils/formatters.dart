import 'package:flutter/material.dart';

const kMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String money(num amount, {bool withCurrency = true}) {
  final negative = amount < 0;
  final value = amount.abs().round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < value.length; i++) {
    buffer.write(value[i]);
    final remaining = value.length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) buffer.write(',');
  }
  return '${negative ? '-' : ''}${withCurrency ? 'LKR ' : ''}$buffer';
}

bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

String shortDate(DateTime date) {
  final today = DateTime.now();
  if (isSameDay(date, today)) return 'Today';
  if (isSameDay(date, today.subtract(const Duration(days: 1)))) return 'Yesterday';
  return '${date.day} ${kMonths[date.month - 1]}';
}

String fullDate(DateTime date) => '${date.day} ${kMonths[date.month - 1]} ${date.year}';

String timeOfDay(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

IconData categoryIcon(String category) {
  final c = category.toLowerCase();
  if (c.contains('food') || c.contains('grocer') || c.contains('dining')) return Icons.shopping_basket_outlined;
  if (c.contains('transport') || c.contains('fuel')) return Icons.directions_bus_outlined;
  if (c.contains('utilit') || c.contains('bill')) return Icons.bolt_outlined;
  if (c.contains('shop')) return Icons.shopping_bag_outlined;
  if (c.contains('educ')) return Icons.school_outlined;
  if (c.contains('health')) return Icons.medical_services_outlined;
  if (c.contains('salary') || c.contains('income')) return Icons.account_balance_outlined;
  if (c.contains('transfer')) return Icons.swap_horiz_rounded;
  return Icons.receipt_long_outlined;
}

/// Maps a transaction category to the budget category it counts toward.
String budgetCategoryFor(String transactionCategory) {
  final c = transactionCategory.toLowerCase();
  if (c.contains('food') || c.contains('grocer') || c.contains('dining')) return 'Food & Groceries';
  if (c.contains('transport') || c.contains('fuel')) return 'Transport & Fuel';
  if (c.contains('utilit') || c.contains('bill')) return 'Utilities & Bills';
  if (c.contains('shop')) return 'Shopping & Lifestyle';
  if (c.contains('educ')) return 'Education & Courses';
  return 'Other';
}

String csvEscape(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
