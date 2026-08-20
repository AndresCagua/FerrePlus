import 'dart:async';

import '../../domain/repositories/offline_repository.dart';
import '../../domain/models/offline_models.dart';
import 'sync_engine.dart';
import 'sync_notification_service.dart';

class OfflineCoordinator {
  OfflineCoordinator({
    required ConnectivityMonitor monitor,
    required SyncEngine engine,
    required SyncNotificationService notifications,
  }) : _engine = engine,
       _notifications = notifications {
    unawaited(_notifications.initialize());
    _subscription = monitor.stabilizedOnline.listen((bool online) {
      if (online) unawaited(syncNow());
    });
  }
  final SyncEngine _engine;
  final SyncNotificationService _notifications;
  late final StreamSubscription<bool> _subscription;
  Future<void> syncNow() async {
    final OfflineSyncResult result = await _engine.syncNow();
    if (result.completed > 0 || result.failed > 0) {
      await _notifications.showPending(result.failed);
    }
  }

  void onUnauthorized() => _engine.onUnauthorized();
  Future<void> resumeAfterLogin() => _engine.resumeAfterLogin();
  Future<void> dispose() async => _subscription.cancel();
}
