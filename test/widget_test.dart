import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spendsmart/app.dart';

void main() {
  testWidgets('App loads home screen and switches tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const SpendSmartApp());

    expect(find.text('SpendSmart'), findsWidgets);
    expect(find.text('Total balance'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.bar_chart_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Understand where your money goes.'), findsOneWidget);
  });
}
