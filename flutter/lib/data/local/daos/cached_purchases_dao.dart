import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../domain/models/commercial_models.dart';
import '../../../domain/repositories/offline_repository.dart';
import '../app_database.dart';

class CachedPurchasesDao extends DatabaseAccessor<AppDatabase>
    implements OfflineCache<Compra> {
  CachedPurchasesDao(super.db);
  $CachedPurchasesTable get cachedPurchases => attachedDatabase.cachedPurchases;

  @override
  Future<void> replace(List<Compra> values) async {
    await batch((Batch batch) {
      batch.deleteAll(cachedPurchases);
      batch.insertAll(
        cachedPurchases,
        values.map(_companion).toList(growable: false),
      );
    });
  }

  @override
  Future<List<Compra>> read() async => (await select(cachedPurchases).get())
      .map((CachedPurchase row) => Compra.fromJson(_decode(row.payloadJson)))
      .toList(growable: false);

  CachedPurchasesCompanion _companion(Compra value) =>
      CachedPurchasesCompanion.insert(
        localKey: value.id.toString(),
        payloadJson: jsonEncode(value.toJson()),
        localUpdatedAt: DateTime.now(),
      );

  Map<String, Object?> _decode(String value) =>
      Map<String, Object?>.from(jsonDecode(value) as Map<Object?, Object?>);
}
