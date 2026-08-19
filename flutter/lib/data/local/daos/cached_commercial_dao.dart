import '../app_database.dart';

abstract class CachedCommercialDao {
  CachedCommercialDao(this.database);
  final AppDatabase database;
}
