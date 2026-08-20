import 'package:drift/drift.dart';
import '../app_database.dart';
import '../../../domain/models/commercial_models.dart';
import '../../../domain/repositories/offline_repository.dart';
import '../../offline/payload_codec.dart';

class CachedSalesDao extends DatabaseAccessor<AppDatabase>
    implements OptimisticOfflineCache<Venta> {
  CachedSalesDao(super.db, {PayloadCodec? codec})
    : _codec = codec ?? PayloadCodec();
  final PayloadCodec _codec;
  $CachedSalesTable get cachedSales => attachedDatabase.cachedSales;
  @override
  Future<void> replace(List<Venta> values) async {
    await delete(cachedSales).go();
    for (final Venta value in values) {
      await into(cachedSales).insert(await _companion(value));
    }
  }

  @override
  Future<List<Venta>> read() async => Future.wait(
    (await select(cachedSales).get()).map(
      (CachedSale row) async =>
          Venta.fromJson(await _codec.decryptOrDecode(row.payloadJson)),
    ),
  );
  @override
  Future<void> upsertOptimistic(Venta value, {String? idempotencyKey}) async {
    await into(cachedSales).insert(
      await _companion(
        value,
        syncState: 'pending',
        idempotencyKey: idempotencyKey,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<CachedSalesCompanion> _companion(
    Venta value, {
    String syncState = 'synced',
    String? idempotencyKey,
  }) async => CachedSalesCompanion.insert(
    localKey: value.id.toString(),
    payloadJson: await _codec.encryptPayload(value.toJson()),
    localUpdatedAt: DateTime.now(),
    syncState: Value(syncState),
    idempotencyKey: Value(idempotencyKey),
  );
}
