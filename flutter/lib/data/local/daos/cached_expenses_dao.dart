import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../domain/models/commercial_models.dart';
import '../../../domain/repositories/offline_repository.dart';
import '../app_database.dart';

class CachedExpensesDao extends DatabaseAccessor<AppDatabase>
    implements OfflineCache<Gasto> {
  CachedExpensesDao(super.db);
  $CachedExpensesTable get cachedExpenses => attachedDatabase.cachedExpenses;

  @override
  Future<void> replace(List<Gasto> values) async {
    await batch((Batch batch) {
      batch.deleteAll(cachedExpenses);
      batch.insertAll(
        cachedExpenses,
        values.map(_companion).toList(growable: false),
      );
    });
  }

  @override
  Future<List<Gasto>> read() async => (await select(cachedExpenses).get())
      .map((CachedExpense row) => Gasto.fromJson(_decode(row.payloadJson)))
      .toList(growable: false);

  CachedExpensesCompanion _companion(Gasto value) =>
      CachedExpensesCompanion.insert(
        localKey: value.id.toString(),
        payloadJson: jsonEncode(value.toJson()),
        localUpdatedAt: DateTime.now(),
      );

  Map<String, Object?> _decode(String value) =>
      Map<String, Object?>.from(jsonDecode(value) as Map<Object?, Object?>);
}
