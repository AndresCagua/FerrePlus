import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../domain/repositories/offline_repository.dart';
import '../../domain/models/offline_models.dart';
import 'sync_engine.dart';
import 'sync_notification_service.dart';

class OfflineCoordinator with WidgetsBindingObserver {
  OfflineCoordinator({
    required ConnectivityMonitor monitor,
    required SyncEngine engine,
    required SyncNotificationService notifications,
  }) : _engine = engine,
       _notifications = notifications {
    WidgetsBinding.instance.addObserver(this);
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
    final int pending = await _engine.countPending();
    if (result.completed > 0 || result.failed > 0 || pending > 0) {
      await _notifications.showPending(pending);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(syncNow());
  }

  void onUnauthorized() => _engine.onUnauthorized();
  Future<void> resumeAfterLogin() => _engine.resumeAfterLogin();
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _subscription.cancel();
  }
}
