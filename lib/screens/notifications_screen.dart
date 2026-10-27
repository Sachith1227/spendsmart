import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.state});
  final AppState state;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark as read after the first frame so the badge clears when leaving.
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.state.markNotificationsRead());
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.state.notifications;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          if (items.isEmpty)
            const EmptyState(icon: Icons.notifications_off_outlined, title: 'You are all caught up!', message: 'Budget alerts and goal updates will appear here.')
          else
            ...items.map((n) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    radius: 18,
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      CircleAvatar(backgroundColor: n.color.withValues(alpha: .1), child: Icon(n.icon, color: n.color)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(n.title, style: const TextStyle(color: kText, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(n.message, style: const TextStyle(color: kMuted, fontSize: 12)),
                        ]),
                      ),
                    ]),
                  ),
                )),
        ],
      ),
    );
  }
}
