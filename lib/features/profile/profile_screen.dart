import 'package:flutter/material.dart';

import 'package:spendsmart/data/services/auth_service.dart';
import 'package:spendsmart/data/state/app_state.dart';
import 'package:spendsmart/core/theme/app_colors.dart';
import 'package:spendsmart/core/utils/formatters.dart';
import 'package:spendsmart/core/widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.state});
  final AppState state;

  Future<void> _editName(BuildContext context) async {
    final controller = TextEditingController(text: state.userName);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(controller: controller, autofocus: true, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !context.mounted) return;
    final error = AuthService.validateName(name);
    if (error != null) return showMessage(context, error);
    try {
      await AuthService.instance.updateDisplayName(name);
    } catch (_) {
      if (context.mounted) showMessage(context, 'Could not update name. Try again.');
      return;
    }
    state.updateUserName(name);
    if (context.mounted) showMessage(context, 'Name updated');
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Log out')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    await AuthService.instance.signOut();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final goalsSaved = state.goals.fold<double>(0, (s, g) => s + g.saved);
          return Scaffold(
            appBar: AppBar(title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w800))),
            body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  const CircleAvatar(radius: 30, backgroundColor: kSoftBlue, child: Icon(Icons.person, color: kGreen, size: 32)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(state.userName, style: const TextStyle(color: kText, fontSize: 19, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      if (AuthService.instance.currentUser?.email case final email?)
                        Text(email, style: const TextStyle(color: kMuted, fontSize: 12)),
                      const Text('Currency: Sri Lankan Rupee (LKR)', style: TextStyle(color: kMuted, fontSize: 12)),
                    ]),
                  ),
                  IconButton(onPressed: () => _editName(context), icon: const Icon(Icons.edit_outlined), tooltip: 'Edit name'),
                ]),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(children: [
                  _stat('Transactions recorded', '${state.transactions.length}'),
                  _stat('Total balance', money(state.balance)),
                  _stat('Active budgets', '${state.budgets.length}'),
                  _stat('Savings goals', '${state.goals.length}'),
                  _stat('Saved toward goals', money(goalsSaved)),
                ]),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _signOut(context),
                style: OutlinedButton.styleFrom(foregroundColor: kRed, side: const BorderSide(color: kRed), minimumSize: const Size.fromHeight(48)),
                icon: const Icon(Icons.logout),
                label: const Text('Log out', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 16),
              const Text('Data is kept in memory for this session.', textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 11)),
            ]),
          );
        },
      );

  Widget _stat(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(color: kMuted))),
          Text(value, style: const TextStyle(color: kText, fontWeight: FontWeight.w700)),
        ]),
      );
}
