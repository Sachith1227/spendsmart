import 'package:flutter/material.dart';

/// Asks for a positive LKR amount. Returns null when cancelled.
Future<double?> showAmountDialog(BuildContext context, {required String title, double? initial, String confirmLabel = 'OK'}) {
  return showDialog<double>(
    context: context,
    builder: (_) => _AmountDialog(title: title, initial: initial, confirmLabel: confirmLabel),
  );
}

class _AmountDialog extends StatefulWidget {
  const _AmountDialog({required this.title, this.initial, required this.confirmLabel});
  final String title, confirmLabel;
  final double? initial;

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  late final _controller = TextEditingController(text: widget.initial?.toStringAsFixed(0) ?? '');
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = double.tryParse(_controller.text.replaceAll(',', '').trim());
    if (value == null || value <= 0) {
      setState(() => _error = 'Enter an amount greater than zero');
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(labelText: 'Amount (LKR)', errorText: _error),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
        ],
      );
}
