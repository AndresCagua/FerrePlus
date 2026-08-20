import 'package:drift/drift.dart';

import '../../../domain/models/commercial_models.dart';
import '../../../domain/repositories/offline_repository.dart';
import '../app_database.dart';
import '../../offline/payload_codec.dart';

class CachedMovementsDao extends DatabaseAccessor<AppDatabase>
    implements
        OptimisticOfflineCache<MovimientoStock>,
        SynchronizableOfflineCache,
        EmptyResponseOfflineCache,
        ClearableOfflineCache {
  CachedMovementsDao(super.db, {PayloadCodec? codec})
    : _codec = codec ?? PayloadCodec();
  final PayloadCodec _codec;
  $CachedMovementsTable get cachedMovements => attachedDatabase.cachedMovements;

  @override
  Future<void> replace(List<MovimientoStock> values) async {
    await attachedDatabase.transaction(() async {
      final List<CachedMovement> pending =
          await (select(cachedMovements)..where(
                ($CachedMovementsTable row) => row.syncState.equals('pending'),
              ))
              .get();
      await (delete(cachedMovements)..where(
            ($CachedMovementsTable row) => row.syncState.equals('synced'),
          ))
          .go();
      for (final MovimientoStock value in values) {
        await into(
          cachedMovements,
        ).insert(await _companion(value), mode: InsertMode.insertOrReplace);
      }
      for (final CachedMovement row in pending) {
        await into(
          cachedMovements,
        ).insert(_rowCompanion(row), mode: InsertMode.insertOrReplace);
      }
    });
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
  Future<void> clear() => delete(cachedMovements).go().then((int _) {});

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
        await (delete(cachedMovements)..where(
              ($CachedMovementsTable row) =>
                  row.localKey.equals(serverId.toString()),
            ))
            .go();
        await (update(cachedMovements)..where(
              ($CachedMovementsTable row) =>
                  row.localKey.equals(localRecordKey),
            ))
            .write(
              CachedMovementsCompanion(localKey: Value(serverId.toString())),
            );
      });
    }
    await (update(cachedMovements)..where(
          ($CachedMovementsTable row) => row.localKey.equals(
            provisionalId != null && provisionalId < 0
                ? serverId.toString()
                : localRecordKey,
          ),
        ))
        .write(
          CachedMovementsCompanion(
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
      (update(cachedMovements)..where(
            ($CachedMovementsTable row) => row.localKey.equals(localRecordKey),
          ))
          .write(
            const CachedMovementsCompanion(
              syncState: Value('synced'),
              idempotencyKey: Value(null),
            ),
          )
          .then((int _) {});

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

  CachedMovementsCompanion _rowCompanion(CachedMovement row) =>
      CachedMovementsCompanion(
        localKey: Value(row.localKey),
        serverId: Value(row.serverId),
        payloadJson: Value(row.payloadJson),
        serverUpdatedAt: Value(row.serverUpdatedAt),
        localUpdatedAt: Value(row.localUpdatedAt),
        syncState: Value(row.syncState),
        idempotencyKey: Value(row.idempotencyKey),
      );
}
