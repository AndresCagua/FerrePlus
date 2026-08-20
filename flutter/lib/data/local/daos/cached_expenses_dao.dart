import 'package:drift/drift.dart';

import '../../../domain/models/commercial_models.dart';
import '../../../domain/repositories/offline_repository.dart';
import '../app_database.dart';
import '../../offline/payload_codec.dart';

class CachedExpensesDao extends DatabaseAccessor<AppDatabase>
    implements
        OptimisticOfflineCache<Gasto>,
        SynchronizableOfflineCache,
        EmptyResponseOfflineCache {
  CachedExpensesDao(super.db, {PayloadCodec? codec})
    : _codec = codec ?? PayloadCodec();
  final PayloadCodec _codec;
  $CachedExpensesTable get cachedExpenses => attachedDatabase.cachedExpenses;

  @override
  Future<void> replace(List<Gasto> values) async {
    await delete(cachedExpenses).go();
    for (final Gasto value in values) {
      await into(cachedExpenses).insert(await _companion(value));
    }
  }

  @override
  Future<List<Gasto>> read() async => Future.wait(
    (await select(cachedExpenses).get()).map(
      (CachedExpense row) async =>
          Gasto.fromJson(await _codec.decryptOrDecode(row.payloadJson)),
    ),
  );

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
    await (update(cachedExpenses)..where(
          ($CachedExpensesTable row) => row.localKey.equals(localRecordKey),
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
}
