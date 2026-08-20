import 'package:drift/drift.dart';

import '../../../domain/models/commercial_models.dart';
import '../../../domain/repositories/offline_repository.dart';
import '../app_database.dart';
import '../../offline/payload_codec.dart';

class CachedPurchasesDao extends DatabaseAccessor<AppDatabase>
    implements OptimisticOfflineCache<Compra>, SynchronizableOfflineCache {
  CachedPurchasesDao(super.db, {PayloadCodec? codec})
    : _codec = codec ?? PayloadCodec();
  final PayloadCodec _codec;
  $CachedPurchasesTable get cachedPurchases => attachedDatabase.cachedPurchases;

  @override
  Future<void> replace(List<Compra> values) async {
    await delete(cachedPurchases).go();
    for (final Compra value in values) {
      await into(cachedPurchases).insert(await _companion(value));
    }
  }

  @override
  Future<List<Compra>> read() async => Future.wait(
    (await select(cachedPurchases).get()).map(
      (CachedPurchase row) async =>
          Compra.fromJson(await _codec.decryptOrDecode(row.payloadJson)),
    ),
  );

  @override
  Future<void> upsertOptimistic(Compra value, {String? idempotencyKey}) async =>
      into(cachedPurchases).insert(
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
    await (update(cachedPurchases)..where(
          ($CachedPurchasesTable row) => row.localKey.equals(localRecordKey),
        ))
        .write(
          CachedPurchasesCompanion(
            serverId: Value(serverId),
            payloadJson: Value(await _codec.encryptPayload(response)),
            serverUpdatedAt: Value(serverUpdatedAt),
            syncState: const Value('synced'),
            idempotencyKey: const Value(null),
          ),
        );
  }

  Future<CachedPurchasesCompanion> _companion(
    Compra value, {
    String syncState = 'synced',
    String? idempotencyKey,
  }) async => CachedPurchasesCompanion.insert(
    localKey: value.id.toString(),
    payloadJson: await _codec.encryptPayload(value.toJson()),
    localUpdatedAt: DateTime.now(),
    syncState: Value(syncState),
    idempotencyKey: Value(idempotencyKey),
  );
}
