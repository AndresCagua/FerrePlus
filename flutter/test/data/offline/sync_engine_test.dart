import 'package:flutter_test/flutter_test.dart';

import 'package:ferreplus/data/offline/adapters/sale_offline_adapter.dart'
    as sale_adapter;
import 'package:ferreplus/data/services/sync_engine.dart';
import 'package:ferreplus/data/services/sync_notification_service.dart';
import 'package:ferreplus/domain/models/offline_models.dart';
import 'package:ferreplus/domain/repositories/offline_repository.dart';

void main() {
  test(
    'sincroniza exclusivamente las operaciones del usuario activo',
    () async {
      final FakeQueue queue = FakeQueue(<PendingOperation>[
        _operation(id: 1, userId: 10),
        _operation(id: 2, userId: 20),
      ]);
      final List<int> sentIds = <int>[];
      final SyncEngine engine = _engine(
        queue: queue,
        activeUserId: 10,
        sender: (PendingOperationEnvelope envelope) async {
          sentIds.add(envelope.operation.id!);
          return <String, Object?>{};
        },
      );

      await engine.syncNow();

      expect(sentIds, <int>[1]);
      expect(queue.operation(2).status, PendingOperationStatus.pending);
    },
  );

  test(
    'resumeAfterLogin reactiva y sincroniza solo al usuario autenticado',
    () async {
      final FakeQueue queue = FakeQueue(<PendingOperation>[
        _operation(
          id: 1,
          userId: 10,
          status: PendingOperationStatus.authRequired,
        ),
        _operation(
          id: 2,
          userId: 20,
          status: PendingOperationStatus.authRequired,
        ),
      ]);
      final List<int> sentIds = <int>[];
      final SyncEngine engine = _engine(
        queue: queue,
        sender: (PendingOperationEnvelope envelope) async {
          sentIds.add(envelope.operation.id!);
          return <String, Object?>{};
        },
      );

      await engine.resumeAfterLogin(userId: 10);

      expect(queue.resetUserIds, <int>[10]);
      expect(sentIds, <int>[1]);
      expect(queue.operation(2).status, PendingOperationStatus.authRequired);
    },
  );

  test(
    'anulacion de venta limpia cache aunque la respuesta no tenga id',
    () async {
      final PendingOperation operation = sale_adapter.voidOperation(42, 10);
      final FakeQueue queue = FakeQueue(<PendingOperation>[
        operation.copyWith(id: 1),
      ]);
      final FakeCache cache = FakeCache();
      final SyncEngine engine = _engine(
        queue: queue,
        activeUserId: 10,
        cache: cache,
        sender: (_) async => <String, Object?>{},
      );

      await engine.syncNow();

      expect(operation.localRecordKey, '42');
      expect(cache.synchronizedWithoutServerIdKeys, <String>['42']);
      expect(cache.syncState, 'synced');
      expect(cache.idempotencyKey, isNull);
    },
  );
}

SyncEngine _engine({
  required FakeQueue queue,
  required PendingOperationSender sender,
  int? activeUserId,
  FakeCache? cache,
}) => SyncEngine(
  queue: queue,
  sender: DioPendingOperationSender(send: sender),
  notifications: SyncNotificationService(),
  activeUserId: activeUserId,
  caches: cache == null
      ? null
      : <OfflineOperationType, SynchronizableOfflineCache>{
          OfflineOperationType.sale: cache,
        },
);

PendingOperation _operation({
  required int id,
  required int userId,
  PendingOperationStatus status = PendingOperationStatus.pending,
}) => PendingOperation(
  id: id,
  operationType: OfflineOperationType.sale,
  endpoint: '/api/ventas',
  httpMethod: 'POST',
  userId: userId,
  idempotencyKey: 'key-$id',
  payload: <String, Object?>{'id': id},
  createdAt: DateTime(2026, 1, id),
  status: status,
);

class FakeQueue
    implements OfflineQueue, UserScopedOfflineQueue, AuthResumableOfflineQueue {
  FakeQueue(List<PendingOperation> operations)
    : _operations = <int, PendingOperation>{
        for (final PendingOperation operation in operations)
          operation.id!: operation,
      };

  final Map<int, PendingOperation> _operations;
  final List<int> resetUserIds = <int>[];

  PendingOperation operation(int id) => _operations[id]!;

  @override
  Future<void> enqueue(PendingOperation operation) async {
    _operations[operation.id!] = operation;
  }

  @override
  Stream<int> watchPendingCount(int userId) => const Stream<int>.empty();

  @override
  Future<List<PendingOperation>> nextBatch({required int limit}) async =>
      _pending(limit: limit);

  @override
  Future<List<PendingOperation>> nextBatchForUser(
    int userId, {
    int limit = 10,
  }) async => _pending(limit: limit, userId: userId);

  List<PendingOperation> _pending({required int limit, int? userId}) =>
      _operations.values
          .where(
            (PendingOperation operation) =>
                operation.status == PendingOperationStatus.pending &&
                (userId == null || operation.userId == userId),
          )
          .take(limit)
          .toList();

  @override
  Future<void> markSyncing(int id) async {
    _operations[id] = _operations[id]!.copyWith(
      status: PendingOperationStatus.syncing,
    );
  }

  @override
  Future<void> markCompleted(int id, Map<String, Object?> response) async {
    _operations[id] = _operations[id]!.copyWith(
      status: PendingOperationStatus.completed,
      response: response,
    );
  }

  @override
  Future<void> markAuthRequired(int id) async {
    _operations[id] = _operations[id]!.copyWith(
      status: PendingOperationStatus.authRequired,
    );
  }

  @override
  Future<void> markFailed(int id, String sanitizedError) async {
    _operations[id] = _operations[id]!.copyWith(
      status: PendingOperationStatus.failed,
      lastError: sanitizedError,
    );
  }

  @override
  Future<void> cleanupCompleted({
    Duration olderThan = const Duration(days: 7),
  }) async {}

  @override
  Future<int> countAll(int userId) async => _operations.values
      .where((PendingOperation item) => item.userId == userId)
      .length;

  @override
  Future<int> totalPayloadSize(int userId) async => 0;

  @override
  Future<void> resetAuthRequiredToPending({int? userId}) async {
    if (userId != null) resetUserIds.add(userId);
    for (final MapEntry<int, PendingOperation> entry in _operations.entries) {
      final PendingOperation operation = entry.value;
      if (operation.status == PendingOperationStatus.authRequired &&
          operation.userId == userId) {
        _operations[entry.key] = operation.copyWith(
          status: PendingOperationStatus.pending,
        );
      }
    }
  }
}

class FakeCache
    implements SynchronizableOfflineCache, EmptyResponseOfflineCache {
  final List<String> synchronizedWithoutServerIdKeys = <String>[];
  String syncState = 'pending';
  String? idempotencyKey = 'local-key';

  @override
  Future<void> markSynchronized({
    required String localRecordKey,
    required int serverId,
    required DateTime serverUpdatedAt,
    required Map<String, Object?> response,
  }) async {
    syncState = 'synced';
    idempotencyKey = null;
  }

  @override
  Future<void> markSynchronizedWithoutServerId({
    required String localRecordKey,
  }) async {
    synchronizedWithoutServerIdKeys.add(localRecordKey);
    syncState = 'synced';
    idempotencyKey = null;
  }
}
