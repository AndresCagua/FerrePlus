import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/offline_providers.dart';

/// Indicador sutil que no bloquea la navegacion ni el FAB.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final ProviderContainer container;
    try {
      container = ProviderScope.containerOf(context, listen: false);
    } on StateError {
      // PageScaffold is also used in isolated widget tests without Riverpod.
      return const SizedBox.shrink();
    }
    container.read(offlineCoordinatorProvider);
    final ValueListenable<bool> syncing = container
        .read(syncEngineProvider)
        .syncing;
    return StreamBuilder<bool>(
      stream: container.read(connectivityMonitorProvider).stabilizedOnline,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) =>
          ValueListenableBuilder<bool>(
            valueListenable: syncing,
            builder: (BuildContext context, bool isSyncing, Widget? child) {
              final String? message = isSyncing
                  ? 'Sincronizando...'
                  : snapshot.data == false
                  ? 'Sin conexión — las operaciones se guardarán'
                  : null;
              if (message == null) return const SizedBox.shrink();
              return MaterialBanner(
                content: Text(message),
                leading: Icon(
                  isSyncing ? Icons.sync : Icons.cloud_off_outlined,
                ),
                actions: const <Widget>[SizedBox.shrink()],
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              );
            },
          ),
    );
  }
}
