import 'package:flutter/material.dart';

import 'package:spendsmart/core/theme/app_colors.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title, message;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: kCardBorder)),
        child: Column(children: [
          Icon(icon, size: 42, color: kGreen),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: kText, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
        ]),
      );
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(17), this.radius = 21});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radius), border: Border.all(color: kCardBorder)),
        child: child,
      );
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 44});
  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(size * .22),
        child: Image.asset('assets/images/logo.png', width: size, height: size, fit: BoxFit.cover),
      );
}

/// "SpendSmart" in brand colours: dark "Spend", gradient green "Smart".
class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.fontSize = 22});
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900, letterSpacing: -fontSize * .03, height: 1.1);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('Spend', style: style.copyWith(color: kBrandDark)),
      ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => const LinearGradient(colors: [kBrandGreen, kBrandGreenLight]).createShader(bounds),
        child: Text('Smart', style: style.copyWith(color: Colors.white)),
      ),
    ]);
  }
}

/// Top bar with logo, notifications bell and profile avatar.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.notificationCount,
    required this.onNotifications,
    required this.onProfile,
    this.showTagline = true,
  });

  final int notificationCount;
  final VoidCallback onNotifications, onProfile;
  final bool showTagline;

  @override
  Widget build(BuildContext context) => Row(children: [
        const AppLogo(),
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const AppWordmark(),
            if (showTagline) const Text('YOUR MONEY, IN CONTROL', style: TextStyle(fontSize: 9, letterSpacing: 1.1, color: kMuted)),
          ]),
        ),
        IconButton(
          onPressed: onNotifications,
          tooltip: 'Notifications',
          icon: Badge(
            isLabelVisible: notificationCount > 0,
            label: Text('$notificationCount'),
            child: const Icon(Icons.notifications_none_rounded, size: 27),
          ),
        ),
        GestureDetector(
          onTap: onProfile,
          child: const CircleAvatar(backgroundColor: kSoftBlue, child: Icon(Icons.person, color: kGreen)),
        ),
      ]);
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.text, required this.warning});
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: warning ? const Color(0xFFFFDAD7) : const Color(0xFFDDF7E6), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: warning ? kRed : kGreen, fontWeight: FontWeight.w800, fontSize: 10)),
      );
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
