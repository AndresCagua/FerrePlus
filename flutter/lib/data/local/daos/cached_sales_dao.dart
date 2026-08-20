import 'package:drift/drift.dart';
import '../app_database.dart';
import '../../../domain/models/commercial_models.dart';
import '../../../domain/repositories/offline_repository.dart';
import '../../offline/payload_codec.dart';

class CachedSalesDao extends DatabaseAccessor<AppDatabase>
    implements
        OptimisticOfflineCache<Venta>,
        SynchronizableOfflineCache,
        EmptyResponseOfflineCache,
        ClearableOfflineCache {
  CachedSalesDao(super.db, {PayloadCodec? codec})
    : _codec = codec ?? PayloadCodec();
  final PayloadCodec _codec;
  $CachedSalesTable get cachedSales => attachedDatabase.cachedSales;
  @override
  Future<void> replace(List<Venta> values) async {
    await attachedDatabase.transaction(() async {
      final List<CachedSale> pending =
          await (select(cachedSales)..where(
                ($CachedSalesTable row) => row.syncState.equals('pending'),
              ))
              .get();
      await (delete(
        cachedSales,
      )..where(($CachedSalesTable row) => row.syncState.equals('synced'))).go();
      for (final Venta value in values) {
        await into(
          cachedSales,
        ).insert(await _companion(value), mode: InsertMode.insertOrReplace);
      }
      for (final CachedSale row in pending) {
        await into(
          cachedSales,
        ).insert(_rowCompanion(row), mode: InsertMode.insertOrReplace);
      }
    });
  }

  @override
  Future<List<Venta>> read() async => Future.wait(
    (await select(cachedSales).get()).map(
      (CachedSale row) async =>
          Venta.fromJson(await _codec.decryptOrDecode(row.payloadJson)),
    ),
  );

  @override
  Future<void> clear() => delete(cachedSales).go().then((int _) {});
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

  @override
  Future<void> markSynchronized({
    required String localRecordKey,
    required int serverId,
    required DateTime serverUpdatedAt,
    required Map<String, Object?> response,
  }) async {
    await (update(cachedSales)..where(
          ($CachedSalesTable row) => row.localKey.equals(localRecordKey),
        ))
        .write(
          CachedSalesCompanion(
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
      (update(cachedSales)..where(
            ($CachedSalesTable row) => row.localKey.equals(localRecordKey),
          ))
          .write(
            const CachedSalesCompanion(
              syncState: Value('synced'),
              idempotencyKey: Value(null),
            ),
          )
          .then((int _) {});

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

  CachedSalesCompanion _rowCompanion(CachedSale row) => CachedSalesCompanion(
    localKey: Value(row.localKey),
    serverId: Value(row.serverId),
    payloadJson: Value(row.payloadJson),
    serverUpdatedAt: Value(row.serverUpdatedAt),
    localUpdatedAt: Value(row.localUpdatedAt),
    syncState: Value(row.syncState),
    idempotencyKey: Value(row.idempotencyKey),
  );
}
