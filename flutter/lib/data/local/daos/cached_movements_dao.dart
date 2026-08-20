import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../domain/models/commercial_models.dart';
import '../../../domain/repositories/offline_repository.dart';
import '../app_database.dart';

class CachedMovementsDao extends DatabaseAccessor<AppDatabase>
    implements OfflineCache<MovimientoStock> {
  CachedMovementsDao(super.db);
  $CachedMovementsTable get cachedMovements => attachedDatabase.cachedMovements;

  @override
  Future<void> replace(List<MovimientoStock> values) async {
    await batch((Batch batch) {
      batch.deleteAll(cachedMovements);
      batch.insertAll(
        cachedMovements,
        values.map(_companion).toList(growable: false),
      );
    });
  }

  @override
  Future<List<MovimientoStock>> read() async =>
      (await select(cachedMovements).get())
          .map(
            (CachedMovement row) =>
                MovimientoStock.fromJson(_decode(row.payloadJson)),
          )
          .toList(growable: false);

  CachedMovementsCompanion _companion(MovimientoStock value) =>
      CachedMovementsCompanion.insert(
        localKey: value.id.toString(),
        payloadJson: jsonEncode(value.toJson()),
        localUpdatedAt: DateTime.now(),
      );

  Map<String, Object?> _decode(String value) =>
      Map<String, Object?>.from(jsonDecode(value) as Map<Object?, Object?>);
}
