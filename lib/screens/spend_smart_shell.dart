import 'package:flutter/material.dart';

import '../models/spend_transaction.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'add_transaction_screen.dart';
import 'analytics_screen.dart';
import 'budgets_screen.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'transactions_screen.dart';

class SpendSmartShell extends StatefulWidget {
  const SpendSmartShell({super.key});

  @override
  State<SpendSmartShell> createState() => _SpendSmartShellState();
}

class _SpendSmartShellState extends State<SpendSmartShell> {
  final _state = AppState();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    final name = AuthService.instance.currentUser?.displayName;
    if (name != null && name.isNotEmpty) _state.userName = name;
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  Future<void> _addTransaction() async {
    final result = await Navigator.of(context).push<SpendTransaction>(
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
    if (result == null || !mounted) return;
    _state.addTransaction(result);
    showMessage(context, 'Transaction added successfully');
  }

  void _openNotifications() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => NotificationsScreen(state: _state)));

  void _openProfile() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileScreen(state: _state)));

  void _selectTab(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        final pages = [
          HomeScreen(
            state: _state,
            onAdd: _addTransaction,
            onViewTransactions: () => _selectTab(1),
            onViewBudgets: () => _selectTab(2),
            onNotifications: _openNotifications,
            onProfile: _openProfile,
          ),
          TransactionsScreen(state: _state, onAdd: _addTransaction),
          BudgetsScreen(state: _state, onNotifications: _openNotifications, onProfile: _openProfile),
          AnalyticsScreen(state: _state),
        ];

        return Scaffold(
          body: IndexedStack(index: _selectedIndex, children: pages),
          floatingActionButton: FloatingActionButton(
            onPressed: _addTransaction,
            backgroundColor: kGreen,
            foregroundColor: Colors.white,
            elevation: 5,
            shape: const CircleBorder(),
            tooltip: 'Add transaction',
            child: const Icon(Icons.add, size: 30),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _selectTab,
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFFDDF3E5),
            height: 70,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Transactions'),
              NavigationDestination(icon: Icon(Icons.pie_chart_outline), selectedIcon: Icon(Icons.pie_chart), label: 'Budgets'),
              NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Analytics'),
            ],
          ),
        );
      },
    );
  }
}
