import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'tables/offline_tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    PendingOperations,
    CachedSales,
    CachedExpenses,
    CachedPurchases,
    CachedMovements,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);
  AppDatabase.memory() : super(NativeDatabase.memory());
  AppDatabase.persistent()
    : super(
        LazyDatabase(() async {
          final Directory directory = await getApplicationDocumentsDirectory();
          return NativeDatabase(
            File(path.join(directory.path, 'ferreplus.sqlite')),
          );
        }),
      );

  static Future<AppDatabase> open() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    return AppDatabase(
      NativeDatabase(File(path.join(directory.path, 'ferreplus.sqlite'))),
    );
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator migrator) => migrator.createAll(),
    onUpgrade: (Migrator migrator, int from, int to) async {},
  );
}
