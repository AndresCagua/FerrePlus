import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

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
  DioPendingOperationSender({
    Dio? dio,
    PendingOperationSender? send,
    Dio Function()? dioReader,
  }) : send =
           send ??
           ((PendingOperationEnvelope operation) =>
               _dispatch(dio ?? dioReader!(), operation));
  final PendingOperationSender send;

  static Future<Map<String, Object?>> _dispatch(
    Dio dio,
    PendingOperationEnvelope envelope,
  ) async {
    final PendingOperation operation = envelope.operation;
    final String type = operation.operationType.value;
    final String endpoint = _endpointFor(operation);
    final bool isPut = operation.httpMethod.toUpperCase() == 'PUT';
    final Response<Object?> response = isPut
        ? await dio.put<Object?>(
            endpoint,
            data: operation.payload,
            options: Options(
              headers: <String, Object?>{
                'X-Idempotency-Key': operation.idempotencyKey,
              },
            ),
          )
        : await dio.post<Object?>(
            endpoint,
            data: operation.payload,
            options: Options(
              headers: <String, Object?>{
                'X-Idempotency-Key': operation.idempotencyKey,
              },
            ),
          );
    if (response.data is Map<Object?, Object?>) {
      return Map<String, Object?>.from(response.data! as Map<Object?, Object?>);
    }
    return <String, Object?>{'operation_type': type};
  }

  static String _endpointFor(PendingOperation operation) =>
      switch (operation.operationType) {
        OfflineOperationType.sale => '/api/ventas',
        OfflineOperationType.expense => '/api/gastos',
        OfflineOperationType.purchase => '/api/compras',
        OfflineOperationType.movement => '/api/movimientos-stock',
        OfflineOperationType.saleVoid =>
          '/api/ventas/${operation.payload['id']}/anular',
        OfflineOperationType.purchaseVoid =>
          '/api/compras/${operation.payload['id']}/anular',
      };
}

class SyncEngine implements OfflineQueue {
  SyncEngine({
    required OfflineQueue queue,
    required DioPendingOperationSender sender,
    required SyncNotificationService notifications,
    int maxAttempts = 5,
    DateTime Function()? clock,
    Random? random,
  }) : _queue = queue,
       _sender = sender.send,
       _notifications = notifications,
       _maxAttempts = maxAttempts,
       _clock = clock ?? DateTime.now,
       _random = random ?? Random();
  final OfflineQueue _queue;
  final PendingOperationSender _sender;
  final SyncNotificationService _notifications;
  final int _maxAttempts;
  final DateTime Function() _clock;
  final Random _random;
  final ValueNotifier<bool> syncing = ValueNotifier<bool>(false);
  final ValueNotifier<bool> authRequired = ValueNotifier<bool>(false);
  bool _running = false;
  bool _paused = false;

  Future<OfflineSyncResult> syncNow() async {
    if (_running || _paused) return const OfflineSyncResult();
    _running = true;
    syncing.value = true;
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
              await _markAllAuthRequired(operation.userId);
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
      syncing.value = false;
    }
  }

  Future<void> resumeAfterLogin() async {
    _paused = false;
    authRequired.value = false;
    await syncNow();
  }

  Future<void> onUnauthorized() async {
    _paused = true;
    authRequired.value = true;
    final List<PendingOperation> operations = await _queue.nextBatch(
      limit: 500,
    );
    final Set<int> userIds = operations
        .map((PendingOperation item) => item.userId)
        .toSet();
    for (final int userId in userIds) {
      await _markAllAuthRequired(userId);
    }
  }

  Future<void> _markAllAuthRequired(int userId) async {
    if (_queue case final AuthRequiredOfflineQueue queue) {
      await queue.markAllAuthRequired(userId);
    } else {
      final List<PendingOperation> operations = await _queue.nextBatch(
        limit: 500,
      );
      for (final PendingOperation item in operations.where(
        (PendingOperation item) => item.userId == userId,
      )) {
        if (item.id != null) await _queue.markAuthRequired(item.id!);
      }
    }
  }

  Future<void> _retry(PendingOperation operation, String error) async {
    final int attempt = operation.attemptCount + 1;
    final int baseSeconds = min(30 * (1 << (attempt - 1)), 1800);
    final int jitterSeconds = _random.nextInt(baseSeconds + 1);
    final int seconds = min(baseSeconds + jitterSeconds, 1800);
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
  Future<void> dispose() async {
    syncing.dispose();
    authRequired.dispose();
  }
}
