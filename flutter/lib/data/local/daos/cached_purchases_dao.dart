import 'package:drift/drift.dart';

import '../../../domain/models/commercial_models.dart';
import '../../../domain/repositories/offline_repository.dart';
import '../app_database.dart';
import '../../offline/payload_codec.dart';

class CachedPurchasesDao extends DatabaseAccessor<AppDatabase>
    implements
        OptimisticOfflineCache<Compra>,
        SynchronizableOfflineCache,
        EmptyResponseOfflineCache,
        ClearableOfflineCache {
  CachedPurchasesDao(super.db, {PayloadCodec? codec})
    : _codec = codec ?? PayloadCodec();
  final PayloadCodec _codec;
  $CachedPurchasesTable get cachedPurchases => attachedDatabase.cachedPurchases;

  @override
  Future<void> replace(List<Compra> values) async {
    await attachedDatabase.transaction(() async {
      final List<CachedPurchase> pending =
          await (select(cachedPurchases)..where(
                ($CachedPurchasesTable row) => row.syncState.equals('pending'),
              ))
              .get();
      await (delete(cachedPurchases)..where(
            ($CachedPurchasesTable row) => row.syncState.equals('synced'),
          ))
          .go();
      for (final Compra value in values) {
        await into(
          cachedPurchases,
        ).insert(await _companion(value), mode: InsertMode.insertOrReplace);
      }
      for (final CachedPurchase row in pending) {
        await into(
          cachedPurchases,
        ).insert(_rowCompanion(row), mode: InsertMode.insertOrReplace);
      }
    });
  }

  @override
  Future<List<Compra>> read() async => Future.wait(
    (await select(cachedPurchases).get()).map(
      (CachedPurchase row) async =>
          Compra.fromJson(await _codec.decryptOrDecode(row.payloadJson)),
    ),
  );

  @override
  Future<void> clear() => delete(cachedPurchases).go().then((int _) {});

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

  @override
  Future<void> markSynchronizedWithoutServerId({
    required String localRecordKey,
  }) =>
      (update(cachedPurchases)..where(
            ($CachedPurchasesTable row) => row.localKey.equals(localRecordKey),
          ))
          .write(
            const CachedPurchasesCompanion(
              syncState: Value('synced'),
              idempotencyKey: Value(null),
            ),
          )
          .then((int _) {});

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

  CachedPurchasesCompanion _rowCompanion(CachedPurchase row) =>
      CachedPurchasesCompanion(
        localKey: Value(row.localKey),
        serverId: Value(row.serverId),
        payloadJson: Value(row.payloadJson),
        serverUpdatedAt: Value(row.serverUpdatedAt),
        localUpdatedAt: Value(row.localUpdatedAt),
        syncState: Value(row.syncState),
        idempotencyKey: Value(row.idempotencyKey),
      );
}
