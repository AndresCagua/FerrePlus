import 'package:flutter/material.dart';

import 'app_empty_state.dart';
import 'app_error_view.dart';
import 'app_loading_indicator.dart';

class CatalogStateView extends StatelessWidget {
  const CatalogStateView({required this.loading, required this.error, required this.empty, required this.content, required this.retry, super.key});
  final bool loading;
  final String? error;
  final bool empty;
  final Widget content;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) {
    if (loading) return const AppLoadingIndicator();
    if (error != null) {
      return AppErrorView(message: error!, onRetry: retry);
    }
    if (empty) {
      return const AppEmptyState(
        title: 'Sin registros',
        subtitle: 'No hay registros disponibles.',
      );
    }
    return content;
  }
}
