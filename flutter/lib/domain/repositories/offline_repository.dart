import '../models/offline_models.dart';

abstract interface class OfflineQueue {
  Future<void> enqueue(PendingOperation operation);
  Stream<int> watchPendingCount(int userId);
  Future<List<PendingOperation>> nextBatch({required int limit});
  Future<void> markSyncing(int id);
  Future<void> markCompleted(int id, Map<String, Object?> response);
  Future<void> markAuthRequired(int id);
  Future<void> markFailed(int id, String sanitizedError);
  Future<void> cleanupCompleted({Duration olderThan = const Duration(days: 7)});
  Future<int> countAll(int userId);
  Future<int> totalPayloadSize(int userId);
}

/// Optional operations used by the synchronizer without changing commercial
/// repository contracts.
abstract interface class AuthRequiredOfflineQueue {
  Future<void> markAllAuthRequired(int userId);
}

/// Optional resume hook kept separate to preserve existing queue fakes.
abstract interface class AuthResumableOfflineQueue {
  Future<void> resetAuthRequiredToPending({int? userId});
}

abstract interface class RetryableOfflineQueue {
  Future<void> markRetry(
    int id, {
    required int attempts,
    required DateTime retryAt,
    required String error,
  });
}

abstract interface class PendingCountOfflineQueue {
  Future<int> countPending();
}

/// Optional user-scoped count used by grouped notifications.
abstract interface class UserPendingCountOfflineQueue {
  Future<int> countPendingForUser(int userId);
}

abstract interface class OfflineCache<T> {
  Future<void> replace(List<T> values);
  Future<List<T>> read();
}

abstract interface class OptimisticOfflineCache<T> implements OfflineCache<T> {
  Future<void> upsertOptimistic(T value, {String? idempotencyKey});
}

/// Optional synchronization hook for updating a cached record after the API
/// assigns its canonical identifier and timestamp.
abstract interface class SynchronizableOfflineCache {
  Future<void> markSynchronized({
    required String localRecordKey,
    required int serverId,
    required DateTime serverUpdatedAt,
    required Map<String, Object?> response,
  });
}

/// Completion hook for successful responses that intentionally have no body.
abstract interface class EmptyResponseOfflineCache {
  Future<void> markSynchronizedWithoutServerId({
    required String localRecordKey,
  });
}

abstract interface class ConnectivityMonitor {
  Stream<bool> get stabilizedOnline;
  Future<void> dispose();
}
