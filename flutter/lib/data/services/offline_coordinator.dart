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
    Iterable<ClearableOfflineCache> caches = const <ClearableOfflineCache>[],
  }) : _engine = engine,
       _notifications = notifications,
       _caches = List<ClearableOfflineCache>.unmodifiable(caches) {
    WidgetsBinding.instance.addObserver(this);
    unawaited(_notifications.initialize());
    _subscription = monitor.stabilizedOnline.listen((bool online) {
      if (online) unawaited(syncNow());
    });
  }
  final SyncEngine _engine;
  final SyncNotificationService _notifications;
  final List<ClearableOfflineCache> _caches;
  int? _currentUserId;
  late final StreamSubscription<bool> _subscription;

  int? get currentUserId => _currentUserId;
  Future<void> syncNow({int? userId}) async {
    final int? effectiveUserId = userId ?? _currentUserId;
    if (effectiveUserId == null) return;
    _engine.setActiveUserId(effectiveUserId);
    final OfflineSyncResult result = await _engine.syncNow();
    final int pending = await _engine.countPendingForUser(effectiveUserId);
    if (result.completed > 0 || result.failed > 0 || pending > 0) {
      await _notifications.showPending(pending);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(syncNow());
  }

  void onUnauthorized() => _engine.onUnauthorized();
  Future<void> setCurrentUserId(int? userId) async {
    _currentUserId = userId;
    _engine.setActiveUserId(userId);
    if (userId == null) {
      // Cache tables have no user_id; logout is the session isolation boundary.
      await Future.wait(
        _caches.map((ClearableOfflineCache cache) => cache.clear()),
      );
    }
  }

  Future<void> resumeAfterLogin({int? userId}) async {
    if (userId != null) _currentUserId = userId;
    _engine.setActiveUserId(_currentUserId);
    await _engine.resumeAfterLogin(userId: _currentUserId);
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _subscription.cancel();
  }
}
