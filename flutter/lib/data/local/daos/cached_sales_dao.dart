import 'dart:convert';
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../../../domain/models/commercial_models.dart';
import '../../../domain/repositories/offline_repository.dart';

class CachedSalesDao extends DatabaseAccessor<AppDatabase>
    implements OfflineCache<Venta> {
  CachedSalesDao(super.db);
  $CachedSalesTable get cachedSales => attachedDatabase.cachedSales;
  @override
  Future<void> replace(List<Venta> values) async {
    await batch((Batch batch) {
      batch.deleteAll(cachedSales);
      batch.insertAll(
        cachedSales,
        values.map((Venta value) => _companion(value)).toList(growable: false),
      );
    });
  }

  @override
  Future<List<Venta>> read() async => (await select(cachedSales).get())
      .map(
        (CachedSale row) => Venta.fromJson(
          Map<String, Object?>.from(
            jsonDecode(row.payloadJson) as Map<Object?, Object?>,
          ),
        ),
      )
      .toList(growable: false);
  CachedSalesCompanion _companion(Venta value) => CachedSalesCompanion.insert(
    localKey: value.id.toString(),
    payloadJson: jsonEncode(value.toJson()),
    localUpdatedAt: DateTime.now(),
  );
}
