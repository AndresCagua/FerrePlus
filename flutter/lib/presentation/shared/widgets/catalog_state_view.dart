import 'package:flutter/material.dart';

class CatalogStateView extends StatelessWidget {
  const CatalogStateView({required this.loading, required this.error, required this.empty, required this.content, required this.retry, super.key});
  final bool loading;
  final String? error;
  final bool empty;
  final Widget content;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[Text(error!), FilledButton(onPressed: retry, child: const Text('Reintentar'))]));
    }
    if (empty) return const Center(child: Text('No hay registros disponibles.'));
    return content;
  }
}
