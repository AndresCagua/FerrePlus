import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ferreplus/domain/models/catalog_models.dart';
import 'package:ferreplus/domain/repositories/catalog_repositories.dart';
import 'package:ferreplus/presentation/features/catalog_providers.dart';

class FakeCategoriaRepository implements CategoriaRepository {
  List<Categoria> values = <Categoria>[];
  int createCalls = 0;
  Completer<Categoria>? createGate;
  @override
  Future<List<Categoria>> list() async => values;
  @override
  Future<Categoria> getById(int id) async =>
      values.firstWhere((Categoria x) => x.id == id);
  @override
  Future<Categoria> create(Categoria value) async {
    createCalls++;
    if (createGate != null) return createGate!.future;
    values = <Categoria>[value.copyWith(id: 1)];
    return values.first;
  }

  @override
  Future<Categoria> update(int id, Categoria value) async {
    values = <Categoria>[value];
    return value;
  }

  @override
  Future<void> delete(int id) async => values = <Categoria>[];
}

class FakeProveedorRepository implements ProveedorRepository {
  List<Proveedor> values = <Proveedor>[];
  @override
  Future<List<Proveedor>> list() async => values;
  @override
  Future<Proveedor> getById(int id) async =>
      values.firstWhere((Proveedor x) => x.id == id);
  @override
  Future<Proveedor> create(Proveedor value) async {
    values = <Proveedor>[value.copyWith(id: 1)];
    return values.first;
  }

  @override
  Future<Proveedor> update(int id, Proveedor value) async {
    values = <Proveedor>[value];
    return value;
  }

  @override
  Future<void> delete(int id) async => values = <Proveedor>[];
}

class FakeClienteRepository implements ClienteRepository {
  List<Cliente> values = <Cliente>[];
  @override
  Future<List<Cliente>> list() async => values;
  @override
  Future<Cliente> getById(int id) async =>
      values.firstWhere((Cliente x) => x.id == id);
  @override
  Future<Cliente> create(Cliente value) async {
    values = <Cliente>[value.copyWith(id: 1)];
    return values.first;
  }

  @override
  Future<Cliente> update(int id, Cliente value) async {
    values = <Cliente>[value];
    return value;
  }

  @override
  Future<void> delete(int id) async => values = <Cliente>[];
}

class FakeProductoRepository implements ProductoRepository {
  List<Producto> values = <Producto>[];
  @override
  Future<List<Producto>> list({String? query, int? categoria}) async => values;
  @override
  Future<Producto> getById(int id) async =>
      values.firstWhere((Producto x) => x.id == id);
  @override
  Future<Producto> create(Producto value) async {
    values = <Producto>[value.copyWith(id: 1)];
    return values.first;
  }

  @override
  Future<Producto> update(int id, Producto value) async {
    values = <Producto>[value];
    return value;
  }

  @override
  Future<void> delete(int id) async => values = <Producto>[];
}

void main() {
  test('los notifiers reflejan crear, recargar y eliminar', () async {
    final FakeCategoriaRepository categories = FakeCategoriaRepository();
    final FakeProveedorRepository suppliers = FakeProveedorRepository();
    final FakeClienteRepository customers = FakeClienteRepository();
    final FakeProductoRepository products = FakeProductoRepository();
    final ProviderContainer container = ProviderContainer(
      overrides: [
        categoriaRepositoryProvider.overrideWithValue(categories),
        proveedorRepositoryProvider.overrideWithValue(suppliers),
        clienteRepositoryProvider.overrideWithValue(customers),
        productoRepositoryProvider.overrideWithValue(products),
      ],
    );
    addTearDown(container.dispose);

    await container.read(categoriasProvider.future);
    await container.read(proveedoresProvider.future);
    await container.read(clientesProvider.future);
    await container.read(productosProvider.future);
    await container
        .read(categoriasProvider.notifier)
        .save(const Categoria(id: 0, nombre: 'A'));
    await container
        .read(proveedoresProvider.notifier)
        .save(const Proveedor(id: 0, nombre: 'B'));
    await container
        .read(clientesProvider.notifier)
        .save(const Cliente(id: 0, nombre: 'C'));
    await container
        .read(productosProvider.notifier)
        .save(const Producto(id: 0, nombre: 'D'));
    expect(container.read(categoriasProvider).value, hasLength(1));
    expect(container.read(proveedoresProvider).value, hasLength(1));
    expect(container.read(clientesProvider).value, hasLength(1));
    expect(container.read(productosProvider).value, hasLength(1));
    await container.read(categoriasProvider.notifier).remove(1);
    await container.read(proveedoresProvider.notifier).remove(1);
    await container.read(clientesProvider.notifier).remove(1);
    await container.read(productosProvider.notifier).remove(1);
    expect(container.read(productosProvider).value, isEmpty);
  });

  test('bloquea mutaciones concurrentes de catalogo', () async {
    final FakeCategoriaRepository categories = FakeCategoriaRepository()
      ..createGate = Completer<Categoria>();
    final ProviderContainer container = ProviderContainer(
      overrides: [categoriaRepositoryProvider.overrideWithValue(categories)],
    );
    addTearDown(container.dispose);
    await container.read(categoriasProvider.future);

    final Future<void> first = container
        .read(categoriasProvider.notifier)
        .save(const Categoria(id: 0, nombre: 'A'));
    await Future<void>.delayed(Duration.zero);
    final Future<void> second = container
        .read(categoriasProvider.notifier)
        .save(const Categoria(id: 0, nombre: 'B'));

    expect(categories.createCalls, 1);
    categories.createGate!.complete(const Categoria(id: 1, nombre: 'A'));
    await Future.wait(<Future<void>>[first, second]);
  });
}
