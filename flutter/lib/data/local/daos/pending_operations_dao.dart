import 'package:drift/drift.dart';

import '../../../domain/models/offline_models.dart' as domain;
import '../../../domain/repositories/offline_repository.dart';
import '../../offline/payload_codec.dart';
import '../app_database.dart';

class PendingOperationsDao extends DatabaseAccessor<AppDatabase>
    implements
        OfflineQueue,
        RetryableOfflineQueue,
        AuthRequiredOfflineQueue,
        AuthResumableOfflineQueue,
        UserScopedOfflineQueue,
        PendingCountOfflineQueue,
        UserPendingCountOfflineQueue {
  /// ADR-31 limits the durable queue to 500 operations and 20 MiB of payload.
  static const int maxOperations = 500;
  static const int maxPayloadBytes = 20 * 1024 * 1024;

  PendingOperationsDao(super.attachedDatabase, {PayloadCodec? codec})
    : _codec = codec ?? PayloadCodec();
  final PayloadCodec _codec;
  $PendingOperationsTable get pendingOperations =>
      attachedDatabase.pendingOperations;

  @override
  Future<int> enqueue(domain.PendingOperation operation) async {
    final int operationCount = await countAll(operation.userId);
    final int payloadSize = await totalPayloadSize(operation.userId);
    final String payloadJson = await _codec.encryptPayload(operation.payload);
    final bool exceedsLimit =
        operationCount >= maxOperations ||
        payloadSize + payloadJson.length > maxPayloadBytes;
    return into(pendingOperations).insert(
      PendingOperationsCompanion.insert(
        operationType: operation.operationType.value,
        endpoint: operation.endpoint,
        httpMethod: operation.httpMethod,
        userId: operation.userId,
        idempotencyKey: operation.idempotencyKey,
        payloadJson: payloadJson,
        createdAt: operation.createdAt,
        status: Value(exceedsLimit ? 'failed' : operation.status.value),
        attemptCount: Value(operation.attemptCount),
        nextRetryAt: Value(operation.nextRetryAt),
        lastError: Value(
          exceedsLimit
              ? 'La cola offline alcanzo su limite; revisa la operacion.'
              : operation.lastError,
        ),
        responseJson: Value(
          operation.response == null
              ? null
              : await _codec.encryptPayload(operation.response!),
        ),
        localRecordKey: Value(operation.localRecordKey),
      ),
    );
  }

  @override
  Future<void> cancelByLocalRecordKey(String localRecordKey) async {
    await (delete(pendingOperations)..where(
          ($PendingOperationsTable row) =>
              row.localRecordKey.equals(localRecordKey) &
              row.operationType.isIn(<String>[
                domain.OfflineOperationType.sale.value,
                domain.OfflineOperationType.expense.value,
                domain.OfflineOperationType.purchase.value,
                domain.OfflineOperationType.movement.value,
              ]),
        ))
        .go();
  }

  @override
  Future<List<domain.PendingOperation>> nextBatch({int limit = 10}) async {
    return nextBatchForUser(null, limit: limit);
  }

  @override
  Future<List<domain.PendingOperation>> nextBatchForUser(
    int? userId, {
    int limit = 10,
  }) async {
    final DateTime now = DateTime.now();
    final query = select(pendingOperations)
      ..where(
        ($PendingOperationsTable row) =>
            row.status.equals(domain.PendingOperationStatus.pending.value) &
            (row.nextRetryAt.isNull() |
                row.nextRetryAt.isSmallerOrEqualValue(now)) &
            (userId == null
                ? const Constant<bool>(true)
                : row.userId.equals(userId)),
      )
      ..orderBy(<OrderingTerm Function($PendingOperationsTable)>[
        ($PendingOperationsTable row) => OrderingTerm.asc(row.createdAt),
        ($PendingOperationsTable row) => OrderingTerm.asc(row.id),
      ])
      ..limit(limit);
    return Future.wait((await query.get()).map(_toDomain));
  }

  @override
  Future<void> markSyncing(int id) =>
      _update(id, const PendingOperationsCompanion(status: Value('syncing')));

  @override
  Future<void> markCompleted(int id, Map<String, Object?> response) async {
    await _update(
      id,
      PendingOperationsCompanion(
        status: const Value('completed'),
        responseJson: Value(await _codec.encryptPayload(response)),
      ),
    );
  }

  @override
  Future<void> markAuthRequired(int id) => _update(
    id,
    const PendingOperationsCompanion(status: Value('auth_required')),
  );

  @override
  Future<void> markAllAuthRequired(int userId) =>
      (update(pendingOperations)..where(
            ($PendingOperationsTable row) =>
                row.userId.equals(userId) &
                row.status.isIn(<String>['pending', 'syncing']),
          ))
          .write(
            const PendingOperationsCompanion(status: Value('auth_required')),
          )
          .then((int _) {});

  @override
  Future<void> resetAuthRequiredToPending({int? userId}) async {
    final updateQuery = update(pendingOperations);
    if (userId == null) {
      updateQuery.where(
        ($PendingOperationsTable row) => row.status.equals('auth_required'),
      );
    } else {
      updateQuery.where(
        ($PendingOperationsTable row) =>
            row.userId.equals(userId) & row.status.equals('auth_required'),
      );
    }
    await updateQuery.write(
      const PendingOperationsCompanion(
        status: Value('pending'),
        attemptCount: Value(0),
        nextRetryAt: Value(null),
      ),
    );
  }

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
  Future<int> countPending() async =>
      (select(pendingOperations)..where(
            ($PendingOperationsTable row) => row.status.isIn(<String>[
              'pending',
              'syncing',
              'auth_required',
            ]),
          ))
          .get()
          .then((List<PendingOperation> rows) => rows.length);

  @override
  Future<int> countPendingForUser(int userId) async =>
      (select(pendingOperations)..where(
            ($PendingOperationsTable row) =>
                row.userId.equals(userId) &
                row.status.isIn(<String>[
                  'pending',
                  'syncing',
                  'auth_required',
                ]),
          ))
          .get()
          .then((List<PendingOperation> rows) => rows.length);

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

  Future<domain.PendingOperation> _toDomain(PendingOperation row) async =>
      domain.PendingOperation(
        id: row.id,
        operationType: domain.OfflineOperationTypeCodec.parse(
          row.operationType,
        ),
        endpoint: row.endpoint,
        httpMethod: row.httpMethod,
        userId: row.userId,
        idempotencyKey: row.idempotencyKey,
        payload: await _codec.decryptOrDecode(row.payloadJson),
        createdAt: row.createdAt,
        status: domain.PendingOperationStatusCodec.parse(row.status),
        attemptCount: row.attemptCount,
        nextRetryAt: row.nextRetryAt,
        lastError: row.lastError,
        response: row.responseJson == null
            ? null
            : await _codec.decryptOrDecode(row.responseJson!),
        localRecordKey: row.localRecordKey,
      );
}
