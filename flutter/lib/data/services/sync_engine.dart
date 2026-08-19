import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/errors/failure.dart';
import '../../data/offline/payload_codec.dart';
import '../../domain/models/offline_models.dart';
import '../../domain/repositories/offline_repository.dart';
import 'sync_notification_service.dart';

typedef PendingOperationSender =
    Future<Map<String, Object?>> Function(PendingOperationEnvelope operation);

class PendingOperationEnvelope {
  const PendingOperationEnvelope(this.operation);
  final PendingOperation operation;
}

class DioPendingOperationSender {
  DioPendingOperationSender({required this.send});
  final PendingOperationSender send;
}

class SyncEngine implements OfflineQueue {
  SyncEngine({
    required OfflineQueue queue,
    required DioPendingOperationSender sender,
    required SyncNotificationService notifications,
    int maxAttempts = 5,
    DateTime Function()? clock,
  }) : _queue = queue,
       _sender = sender.send,
       _notifications = notifications,
       _maxAttempts = maxAttempts,
       _clock = clock ?? DateTime.now;
  final OfflineQueue _queue;
  final PendingOperationSender _sender;
  final SyncNotificationService _notifications;
  final int _maxAttempts;
  final DateTime Function() _clock;
  bool _running = false;
  bool _paused = false;

  Future<OfflineSyncResult> syncNow() async {
    if (_running || _paused) return const OfflineSyncResult();
    _running = true;
    int completed = 0;
    int failed = 0;
    bool authRequired = false;
    try {
      while (true) {
        final List<PendingOperation> batch = await _queue.nextBatch(limit: 10);
        if (batch.isEmpty) break;
        for (final PendingOperation operation in batch) {
          try {
            await _queue.markSyncing(operation.id!);
            final Map<String, Object?> response = await _sender(
              PendingOperationEnvelope(operation),
            );
            await _queue.markCompleted(operation.id!, response);
            completed++;
          } on DioException catch (error) {
            if (error.response?.statusCode == 401) {
              await _queue.markAuthRequired(operation.id!);
              _paused = true;
              authRequired = true;
              await _notifications.showAuthRequired();
              break;
            }
            final bool terminal =
                error.response?.statusCode == 409 ||
                error.response?.statusCode == 422 ||
                operation.attemptCount + 1 >= _maxAttempts;
            if (terminal) {
              await _queue.markFailed(operation.id!, sanitizeError(error));
              failed++;
              await _notifications.showFailure();
            } else {
              await _retry(operation, sanitizeError(error));
            }
          } on Failure catch (error) {
            await _queue.markFailed(operation.id!, sanitizeError(error));
            failed++;
          }
        }
        if (authRequired) break;
      }
      await _queue.cleanupCompleted();
      return OfflineSyncResult(
        completed: completed,
        failed: failed,
        authRequired: authRequired,
      );
    } finally {
      _running = false;
    }
  }

  Future<void> resumeAfterLogin() async {
    _paused = false;
    await syncNow();
  }

  void onUnauthorized() => _paused = true;
  Future<void> _retry(PendingOperation operation, String error) async {
    final int attempt = operation.attemptCount + 1;
    final int seconds = (30 * (1 << (attempt - 1))).clamp(30, 1800);
    final dynamic queue = _queue;
    if (queue is RetryableOfflineQueue) {
      await queue.markRetry(
        operation.id!,
        attempts: attempt,
        retryAt: _clock().add(Duration(seconds: seconds)),
        error: error,
      );
    }
  }

  @override
  Future<void> enqueue(PendingOperation operation) => _queue.enqueue(operation);
  @override
  Stream<int> watchPendingCount(int userId) => _queue.watchPendingCount(userId);
  @override
  Future<List<PendingOperation>> nextBatch({required int limit}) =>
      _queue.nextBatch(limit: limit);
  @override
  Future<void> markSyncing(int id) => _queue.markSyncing(id);
  @override
  Future<void> markCompleted(int id, Map<String, Object?> response) =>
      _queue.markCompleted(id, response);
  @override
  Future<void> markAuthRequired(int id) => _queue.markAuthRequired(id);
  @override
  Future<void> markFailed(int id, String error) => _queue.markFailed(id, error);
  @override
  Future<void> cleanupCompleted({
    Duration olderThan = const Duration(days: 7),
  }) => _queue.cleanupCompleted(olderThan: olderThan);
  @override
  Future<int> countAll(int userId) => _queue.countAll(userId);
  @override
  Future<int> totalPayloadSize(int userId) => _queue.totalPayloadSize(userId);
  Future<void> dispose() async {}
}
