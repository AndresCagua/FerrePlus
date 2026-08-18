import 'package:flutter/material.dart';

import 'app_loading_indicator.dart';

Future<bool> confirmDelete(BuildContext context, String name) async =>
    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Confirmar eliminacion'),
        content: Text('¿Eliminar $name?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    ) ??
    false;

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ) ??
    false;

Future<bool> showAsyncConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required Future<bool> Function() onConfirm,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => _AsyncConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        onConfirm: onConfirm,
      ),
    ) ??
    false;

class _AsyncConfirmDialog extends StatefulWidget {
  const _AsyncConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
  });
  final String title;
  final String message;
  final String confirmLabel;
  final Future<bool> Function() onConfirm;

  @override
  State<_AsyncConfirmDialog> createState() => _AsyncConfirmDialogState();
}

class _AsyncConfirmDialogState extends State<_AsyncConfirmDialog> {
  bool loading = false;

  Future<void> confirm() async {
    if (loading) return;
    setState(() => loading = true);
    final bool confirmed = await widget.onConfirm();
    if (!mounted) return;
    if (confirmed) Navigator.pop(context, true);
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Text(widget.message),
    actions: <Widget>[
      TextButton(
        onPressed: loading ? null : () => Navigator.pop(context, false),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: loading ? null : confirm,
        child: loading
            ? const AppLoadingIndicator()
            : Text(widget.confirmLabel),
      ),
    ],
  );
}
