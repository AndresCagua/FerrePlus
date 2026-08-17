import 'package:flutter/material.dart';

class CatalogStateView extends StatelessWidget {
  const CatalogStateView({required this.loading, required this.error, required this.empty, required this.content, required this.retry, super.key});
  final bool loading;
  final String? error;
  final bool empty;
  final Widget content;
  final VoidCallback retry;
  @override Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[Text(error!), FilledButton(onPressed: retry, child: const Text('Reintentar'))]));
    if (empty) return const Center(child: Text('No hay registros disponibles.'));
    return content;
  }
}

Future<bool> confirmDelete(BuildContext context, String name) async => await showDialog<bool>(context: context, builder: (BuildContext context) => AlertDialog(title: const Text('Confirmar eliminacion'), content: Text('¿Eliminar $name?'), actions: <Widget>[TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar'))])) ?? false;

class PermissionVisibility extends StatelessWidget {
  const PermissionVisibility({required this.allowed, required this.child, super.key});
  final bool allowed;
  final Widget child;
  @override Widget build(BuildContext context) => allowed ? child : const SizedBox.shrink();
}
