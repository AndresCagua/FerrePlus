import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/catalog_repositories_impl.dart';
import '../../domain/models/catalog_models.dart';
import '../../domain/repositories/catalog_repositories.dart';
import '../../core/providers/auth_providers.dart';

final categoriaRepositoryProvider = Provider<CategoriaRepository>(
  (ref) => CategoriaRepositoryImpl(ref.watch(apiClientProvider).dio),
);
final proveedorRepositoryProvider = Provider<ProveedorRepository>(
  (ref) => ProveedorRepositoryImpl(ref.watch(apiClientProvider).dio),
);
final clienteRepositoryProvider = Provider<ClienteRepository>(
  (ref) => ClienteRepositoryImpl(ref.watch(apiClientProvider).dio),
);
final productoRepositoryProvider = Provider<ProductoRepository>(
  (ref) => ProductoRepositoryImpl(ref.watch(apiClientProvider).dio),
);

final categoriasProvider =
    AsyncNotifierProvider<CategoriasNotifier, List<Categoria>>(
      CategoriasNotifier.new,
    );
final proveedoresProvider =
    AsyncNotifierProvider<ProveedoresNotifier, List<Proveedor>>(
      ProveedoresNotifier.new,
    );
final clientesProvider = AsyncNotifierProvider<ClientesNotifier, List<Cliente>>(
  ClientesNotifier.new,
);
final productosProvider =
    AsyncNotifierProvider<ProductosNotifier, List<Producto>>(
      ProductosNotifier.new,
    );

class CategoriasNotifier extends AsyncNotifier<List<Categoria>> {
  late final CategoriaRepository repository;
  bool mutationInFlight = false;
  @override
  Future<List<Categoria>> build() {
    repository = ref.watch(categoriaRepositoryProvider);
    return repository.list();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(repository.list);
  }

  Future<void> save(Categoria value) async {
    if (mutationInFlight) return;
    mutationInFlight = true;
    state = const AsyncLoading();
    try {
      await (value.id == 0
          ? repository.create(value)
          : repository.update(value.id, value));
      await reload();
    } catch (error, stack) {
      state = AsyncError<List<Categoria>>(error, stack);
      rethrow;
    } finally {
      mutationInFlight = false;
    }
  }

  Future<void> remove(int id) async {
    if (mutationInFlight) return;
    mutationInFlight = true;
    state = const AsyncLoading();
    try {
      await repository.delete(id);
      await reload();
    } catch (error, stack) {
      state = AsyncError<List<Categoria>>(error, stack);
      rethrow;
    } finally {
      mutationInFlight = false;
    }
  }
}

class ProveedoresNotifier extends AsyncNotifier<List<Proveedor>> {
  late final ProveedorRepository repository;
  bool mutationInFlight = false;
  @override
  Future<List<Proveedor>> build() {
    repository = ref.watch(proveedorRepositoryProvider);
    return repository.list();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(repository.list);
  }

  Future<void> save(Proveedor value) async {
    if (mutationInFlight) return;
    mutationInFlight = true;
    state = const AsyncLoading();
    try {
      await (value.id == 0
          ? repository.create(value)
          : repository.update(value.id, value));
      await reload();
    } catch (error, stack) {
      state = AsyncError<List<Proveedor>>(error, stack);
      rethrow;
    } finally {
      mutationInFlight = false;
    }
  }

  Future<void> remove(int id) async {
    if (mutationInFlight) return;
    mutationInFlight = true;
    state = const AsyncLoading();
    try {
      await repository.delete(id);
      await reload();
    } catch (error, stack) {
      state = AsyncError<List<Proveedor>>(error, stack);
      rethrow;
    } finally {
      mutationInFlight = false;
    }
  }
}

class ClientesNotifier extends AsyncNotifier<List<Cliente>> {
  late final ClienteRepository repository;
  bool mutationInFlight = false;
  @override
  Future<List<Cliente>> build() {
    repository = ref.watch(clienteRepositoryProvider);
    return repository.list();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(repository.list);
  }

  Future<void> save(Cliente value) async {
    if (mutationInFlight) return;
    mutationInFlight = true;
    state = const AsyncLoading();
    try {
      await (value.id == 0
          ? repository.create(value)
          : repository.update(value.id, value));
      await reload();
    } catch (error, stack) {
      state = AsyncError<List<Cliente>>(error, stack);
      rethrow;
    } finally {
      mutationInFlight = false;
    }
  }

  Future<void> remove(int id) async {
    if (mutationInFlight) return;
    mutationInFlight = true;
    state = const AsyncLoading();
    try {
      await repository.delete(id);
      await reload();
    } catch (error, stack) {
      state = AsyncError<List<Cliente>>(error, stack);
      rethrow;
    } finally {
      mutationInFlight = false;
    }
  }
}

class ProductosNotifier extends AsyncNotifier<List<Producto>> {
  late final ProductoRepository repository;
  bool mutationInFlight = false;
  String? query;
  int? categoria;
  @override
  Future<List<Producto>> build() {
    repository = ref.watch(productoRepositoryProvider);
    return repository.list();
  }

  Future<void> search({String? value, int? categoriaId}) async {
    query = value;
    categoria = categoriaId;
    await reload();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => repository.list(query: query, categoria: categoria),
    );
  }

  Future<void> save(Producto value) async {
    if (mutationInFlight) return;
    mutationInFlight = true;
    state = const AsyncLoading();
    try {
      await (value.id == 0
          ? repository.create(value)
          : repository.update(value.id, value));
      await reload();
    } catch (error, stack) {
      state = AsyncError<List<Producto>>(error, stack);
      rethrow;
    } finally {
      mutationInFlight = false;
    }
  }

  Future<void> remove(int id) async {
    if (mutationInFlight) return;
    mutationInFlight = true;
    state = const AsyncLoading();
    try {
      await repository.delete(id);
      await reload();
    } catch (error, stack) {
      state = AsyncError<List<Producto>>(error, stack);
      rethrow;
    } finally {
      mutationInFlight = false;
    }
  }
}
