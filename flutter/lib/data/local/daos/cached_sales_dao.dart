import 'dart:convert';
import 'package:drift/drift.dart';
import '../app_database.dart';

class CachedSalesDao extends DatabaseAccessor<AppDatabase> {
  CachedSalesDao(super.db);
  $CachedSalesTable get cachedSales => attachedDatabase.cachedSales;
  Future<void> replace(List<Map<String, Object?>> values) async {
    await batch((Batch batch) {
      batch.deleteAll(cachedSales);
      batch.insertAll(
        cachedSales,
        values.map(_companion).toList(growable: false),
      );
    });
  }

  Future<List<Map<String, Object?>>> read() async =>
      (await select(cachedSales).get())
          .map(
            (CachedSale row) => Map<String, Object?>.from(
              jsonDecode(row.payloadJson) as Map<Object?, Object?>,
            ),
          )
          .toList(growable: false);
  CachedSalesCompanion _companion(Map<String, Object?> value) =>
      CachedSalesCompanion.insert(
        localKey: value['localKey']! as String,
        payloadJson: jsonEncode(value['payload'] ?? value),
        localUpdatedAt: DateTime.now(),
      );
}
