import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../domain/models/offline_models.dart' as domain;
import '../../../domain/repositories/offline_repository.dart';
import '../app_database.dart';

class PendingOperationsDao extends DatabaseAccessor<AppDatabase>
    implements OfflineQueue, RetryableOfflineQueue {
  PendingOperationsDao(super.attachedDatabase);
  $PendingOperationsTable get pendingOperations =>
      attachedDatabase.pendingOperations;

  @override
  Future<int> enqueue(domain.PendingOperation operation) async =>
      into(pendingOperations).insert(
        PendingOperationsCompanion.insert(
          operationType: operation.operationType.value,
          endpoint: operation.endpoint,
          httpMethod: operation.httpMethod,
          userId: operation.userId,
          idempotencyKey: operation.idempotencyKey,
          payloadJson: jsonEncode(operation.payload),
          createdAt: operation.createdAt,
          status: Value(operation.status.value),
          attemptCount: Value(operation.attemptCount),
          nextRetryAt: Value(operation.nextRetryAt),
          lastError: Value(operation.lastError),
          responseJson: Value(
            operation.response == null ? null : jsonEncode(operation.response),
          ),
          localRecordKey: Value(operation.localRecordKey),
        ),
      );

  @override
  Future<List<domain.PendingOperation>> nextBatch({int limit = 10}) async {
    final DateTime now = DateTime.now();
    final query = select(pendingOperations)
      ..where(
        ($PendingOperationsTable row) =>
            row.status.equals(domain.PendingOperationStatus.pending.value) &
            (row.nextRetryAt.isNull() |
                row.nextRetryAt.isSmallerOrEqualValue(now)),
      )
      ..orderBy(<OrderingTerm Function($PendingOperationsTable)>[
        ($PendingOperationsTable row) => OrderingTerm.asc(row.createdAt),
        ($PendingOperationsTable row) => OrderingTerm.asc(row.id),
      ])
      ..limit(limit);
    return (await query.get()).map(_toDomain).toList(growable: false);
  }

  @override
  Future<void> markSyncing(int id) =>
      _update(id, const PendingOperationsCompanion(status: Value('syncing')));

  @override
  Future<void> markCompleted(int id, Map<String, Object?> response) => _update(
    id,
    PendingOperationsCompanion(
      status: const Value('completed'),
      responseJson: Value(jsonEncode(response)),
    ),
  );

  @override
  Future<void> markAuthRequired(int id) => _update(
    id,
    const PendingOperationsCompanion(status: Value('auth_required')),
  );

  @override
  Future<void> markFailed(int id, String error) => _update(
    id,
    PendingOperationsCompanion(
      status: const Value('failed'),
      lastError: Value(error),
    ),
  );

  @override
  Future<void> markRetry(
    int id, {
    required int attempts,
    required DateTime retryAt,
    required String error,
  }) => _update(
    id,
    PendingOperationsCompanion(
      status: const Value('pending'),
      attemptCount: Value(attempts),
      nextRetryAt: Value(retryAt),
      lastError: Value(error),
    ),
  );

  @override
  Stream<int> watchPendingCount(int userId) {
    final query = selectOnly(pendingOperations)
      ..addColumns([pendingOperations.id.count()])
      ..where(
        pendingOperations.userId.equals(userId) &
            pendingOperations.status.isNotIn(<String>['completed', 'failed']),
      );
    return query.watchSingle().map(
      (TypedResult row) => row.read(pendingOperations.id.count()) ?? 0,
    );
  }

  @override
  Future<int> countAll(int userId) async =>
      (await (select(pendingOperations)..where(
                ($PendingOperationsTable row) => row.userId.equals(userId),
              ))
              .get())
          .length;

  @override
  Future<int> totalPayloadSize(int userId) async {
    final List<PendingOperation> rows = await (select(
      pendingOperations,
    )..where(($PendingOperationsTable row) => row.userId.equals(userId))).get();
    return rows.fold<int>(
      0,
      (int total, PendingOperation row) => total + row.payloadJson.length,
    );
  }

  @override
  Future<void> cleanupCompleted({
    Duration olderThan = const Duration(days: 7),
  }) =>
      (delete(pendingOperations)..where(
            ($PendingOperationsTable row) =>
                row.status.equals('completed') &
                row.createdAt.isSmallerThanValue(
                  DateTime.now().subtract(olderThan),
                ),
          ))
          .go()
          .then((int _) {});

  Future<void> _update(int id, PendingOperationsCompanion values) async {
    await (update(
      pendingOperations,
    )..where(($PendingOperationsTable row) => row.id.equals(id))).write(values);
  }

  domain.PendingOperation _toDomain(PendingOperation row) =>
      domain.PendingOperation(
        id: row.id,
        operationType: domain.OfflineOperationTypeCodec.parse(
          row.operationType,
        ),
        endpoint: row.endpoint,
        httpMethod: row.httpMethod,
        userId: row.userId,
        idempotencyKey: row.idempotencyKey,
        payload: Map<String, Object?>.from(
          jsonDecode(row.payloadJson) as Map<Object?, Object?>,
        ),
        createdAt: row.createdAt,
        status: domain.PendingOperationStatusCodec.parse(row.status),
        attemptCount: row.attemptCount,
        nextRetryAt: row.nextRetryAt,
        lastError: row.lastError,
        response: row.responseJson == null
            ? null
            : Map<String, Object?>.from(
                jsonDecode(row.responseJson!) as Map<Object?, Object?>,
              ),
        localRecordKey: row.localRecordKey,
      );
}
