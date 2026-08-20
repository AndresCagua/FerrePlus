import 'package:drift/drift.dart';

import '../../../domain/models/commercial_models.dart';
import '../../../domain/repositories/offline_repository.dart';
import '../app_database.dart';
import '../../offline/payload_codec.dart';

class CachedPurchasesDao extends DatabaseAccessor<AppDatabase>
    implements OptimisticOfflineCache<Compra> {
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
