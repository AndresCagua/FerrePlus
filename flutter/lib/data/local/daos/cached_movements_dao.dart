import 'package:drift/drift.dart';

import '../../../domain/models/commercial_models.dart';
import '../../../domain/repositories/offline_repository.dart';
import '../app_database.dart';
import '../../offline/payload_codec.dart';

class CachedMovementsDao extends DatabaseAccessor<AppDatabase>
    implements OptimisticOfflineCache<MovimientoStock> {
  CachedMovementsDao(super.db, {PayloadCodec? codec})
    : _codec = codec ?? PayloadCodec();
  final PayloadCodec _codec;
  $CachedMovementsTable get cachedMovements => attachedDatabase.cachedMovements;

  @override
  Future<void> replace(List<MovimientoStock> values) async {
    await delete(cachedMovements).go();
    for (final MovimientoStock value in values) {
      await into(cachedMovements).insert(await _companion(value));
    }
  }

  @override
  Future<List<MovimientoStock>> read() async => Future.wait(
    (await select(cachedMovements).get()).map(
      (CachedMovement row) async => MovimientoStock.fromJson(
        await _codec.decryptOrDecode(row.payloadJson),
      ),
    ),
  );

  @override
  Future<void> upsertOptimistic(
    MovimientoStock value, {
    String? idempotencyKey,
  }) async => into(cachedMovements).insert(
    await _companion(
      value,
      syncState: 'pending',
      idempotencyKey: idempotencyKey,
    ),
    mode: InsertMode.insertOrReplace,
  );
  Future<CachedMovementsCompanion> _companion(
    MovimientoStock value, {
    String syncState = 'synced',
    String? idempotencyKey,
  }) async => CachedMovementsCompanion.insert(
    localKey: value.id.toString(),
    payloadJson: await _codec.encryptPayload(value.toJson()),
    localUpdatedAt: DateTime.now(),
    syncState: Value(syncState),
    idempotencyKey: Value(idempotencyKey),
  );
}
