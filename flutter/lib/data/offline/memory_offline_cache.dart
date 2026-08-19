import '../../domain/repositories/offline_repository.dart';

class MemoryOfflineCache<T> implements OfflineCache<T> {
  List<T> _values = <T>[];
  @override
  Future<void> replace(List<T> values) async =>
      _values = List<T>.unmodifiable(values);
  @override
  Future<List<T>> read() async => _values;
}
