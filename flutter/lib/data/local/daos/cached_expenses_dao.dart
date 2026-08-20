import 'package:drift/drift.dart';

import '../../../domain/models/commercial_models.dart';
import '../../../domain/repositories/offline_repository.dart';
import '../app_database.dart';
import '../../offline/payload_codec.dart';

class CachedExpensesDao extends DatabaseAccessor<AppDatabase>
    implements
        OptimisticOfflineCache<Gasto>,
        SynchronizableOfflineCache,
        EmptyResponseOfflineCache,
        ClearableOfflineCache {
  CachedExpensesDao(super.db, {PayloadCodec? codec})
    : _codec = codec ?? PayloadCodec();
  final PayloadCodec _codec;
  $CachedExpensesTable get cachedExpenses => attachedDatabase.cachedExpenses;

  @override
  Future<void> replace(List<Gasto> values) async {
    await attachedDatabase.transaction(() async {
      final List<CachedExpense> pending =
          await (select(cachedExpenses)..where(
                ($CachedExpensesTable row) => row.syncState.equals('pending'),
              ))
              .get();
      await (delete(cachedExpenses)..where(
            ($CachedExpensesTable row) => row.syncState.equals('synced'),
          ))
          .go();
      for (final Gasto value in values) {
        await into(
          cachedExpenses,
        ).insert(await _companion(value), mode: InsertMode.insertOrReplace);
      }
      for (final CachedExpense row in pending) {
        await into(
          cachedExpenses,
        ).insert(_rowCompanion(row), mode: InsertMode.insertOrReplace);
      }
    });
  }

  @override
  Future<List<Gasto>> read() async => Future.wait(
    (await select(cachedExpenses).get()).map(
      (CachedExpense row) async =>
          Gasto.fromJson(await _codec.decryptOrDecode(row.payloadJson)),
    ),
  );

  @override
  Future<void> clear() => delete(cachedExpenses).go().then((int _) {});

  @override
  Future<void> upsertOptimistic(Gasto value, {String? idempotencyKey}) async =>
      into(cachedExpenses).insert(
        await _companion(
          value,
          syncState: 'pending',
          idempotencyKey: idempotencyKey,
        ),
        mode: InsertMode.insertOrReplace,
      );

  @override
  Future<void> markSynchronized({
    required String localRecordKey,
    required int serverId,
    required DateTime serverUpdatedAt,
    required Map<String, Object?> response,
  }) async {
    final int? provisionalId = int.tryParse(localRecordKey);
    if (provisionalId != null && provisionalId < 0) {
      await attachedDatabase.transaction(() async {
        await (delete(cachedExpenses)..where(
              ($CachedExpensesTable row) =>
                  row.localKey.equals(serverId.toString()),
            ))
            .go();
        await (update(cachedExpenses)..where(
              ($CachedExpensesTable row) => row.localKey.equals(localRecordKey),
            ))
            .write(
              CachedExpensesCompanion(localKey: Value(serverId.toString())),
            );
      });
    }
    await (update(cachedExpenses)..where(
          ($CachedExpensesTable row) => row.localKey.equals(
            provisionalId != null && provisionalId < 0
                ? serverId.toString()
                : localRecordKey,
          ),
        ))
        .write(
          CachedExpensesCompanion(
            serverId: Value(serverId),
            payloadJson: Value(await _codec.encryptPayload(response)),
            serverUpdatedAt: Value(serverUpdatedAt),
            syncState: const Value('synced'),
            idempotencyKey: const Value(null),
          ),
        );
  }

  @override
  Future<void> markSynchronizedWithoutServerId({
    required String localRecordKey,
  }) =>
      (update(cachedExpenses)..where(
            ($CachedExpensesTable row) => row.localKey.equals(localRecordKey),
          ))
          .write(
            const CachedExpensesCompanion(
              syncState: Value('synced'),
              idempotencyKey: Value(null),
            ),
          )
          .then((int _) {});

  Future<CachedExpensesCompanion> _companion(
    Gasto value, {
    String syncState = 'synced',
    String? idempotencyKey,
  }) async => CachedExpensesCompanion.insert(
    localKey: value.id.toString(),
    payloadJson: await _codec.encryptPayload(value.toJson()),
    localUpdatedAt: DateTime.now(),
    syncState: Value(syncState),
    idempotencyKey: Value(idempotencyKey),
  );

  CachedExpensesCompanion _rowCompanion(CachedExpense row) =>
      CachedExpensesCompanion(
        localKey: Value(row.localKey),
        serverId: Value(row.serverId),
        payloadJson: Value(row.payloadJson),
        serverUpdatedAt: Value(row.serverUpdatedAt),
        localUpdatedAt: Value(row.localUpdatedAt),
        syncState: Value(row.syncState),
        idempotencyKey: Value(row.idempotencyKey),
      );
}
