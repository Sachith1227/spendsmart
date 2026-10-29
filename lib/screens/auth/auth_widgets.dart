import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: kText,
            side: const BorderSide(color: kCardBorder),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Text('G', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF4285F4))),
          label: const Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.loading = false});
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: loading ? null : onPressed,
          style: FilledButton.styleFrom(backgroundColor: kGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ),
      );
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Row(children: [
          Expanded(child: Divider(color: kCardBorder)),
          Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('or', style: TextStyle(color: kMuted))),
          Expanded(child: Divider(color: kCardBorder)),
        ]),
      );
}

InputDecoration authInput(String label, IconData icon, {Widget? suffix}) => InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kCardBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kCardBorder)),
    );
