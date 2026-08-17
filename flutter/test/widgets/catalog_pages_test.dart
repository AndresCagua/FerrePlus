import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ferreplus/domain/models/auth_state.dart';
import 'package:ferreplus/domain/models/catalog_models.dart';
import 'package:ferreplus/domain/repositories/catalog_repositories.dart';
import 'package:ferreplus/core/providers/auth_providers.dart';
import 'package:ferreplus/presentation/features/catalog_providers.dart';
import 'package:ferreplus/presentation/features/productos/productos_pages.dart';

class ProductRepositoryFake implements ProductoRepository {
  ProductRepositoryFake(this.items);
  List<Producto> items;
  bool throwOnList = false;
  int? deletedId;
  Producto? created;
  Producto? updated;

  @override
  Future<List<Producto>> list({String? query, int? categoria}) async {
    if (throwOnList) throw StateError('fallo de red');
    return items;
  }

  @override
  Future<Producto> create(Producto value) async {
    created = value;
    items = <Producto>[value.copyWith(id: 2)];
    return items.first;
  }

  @override
  Future<Producto> update(int id, Producto value) async {
    updated = value;
    items = <Producto>[value];
    return value;
  }

  @override
  Future<void> delete(int id) async {
    deletedId = id;
    items = items.where((Producto item) => item.id != id).toList();
  }
}

class CategoriesFake implements CategoriaRepository {
  @override
  Future<List<Categoria>> list() async => <Categoria>[
    const Categoria(id: 4, nombre: 'Herramientas'),
  ];
  @override
  Future<Categoria> create(Categoria value) async => value;
  @override
  Future<Categoria> update(int id, Categoria value) async => value;
  @override
  Future<void> delete(int id) async {}
}

class SuppliersFake implements ProveedorRepository {
  @override
  Future<List<Proveedor>> list() async => <Proveedor>[
    const Proveedor(id: 8, nombre: 'Acme'),
  ];
  @override
  Future<Proveedor> create(Proveedor value) async => value;
  @override
  Future<Proveedor> update(int id, Proveedor value) async => value;
  @override
  Future<void> delete(int id) async {}
}

class FixedAuthNotifier extends AuthNotifier {
  FixedAuthNotifier(this.value);
  final AuthState value;

  @override
  AuthState build() => value;
}

Widget buildTestApp({
  required Widget child,
  required ProductRepositoryFake products,
  AuthState auth = const AuthState(
    status: AuthStatus.authenticated,
    permisos: <String>{
      'PRODUCTOS_VER',
      'PRODUCTOS_CREAR',
      'PRODUCTOS_EDITAR',
      'PRODUCTOS_ELIMINAR',
    },
  ),
}) {
  return ProviderScope(
    key: UniqueKey(),
    overrides: [
      authNotifierProvider.overrideWith(() => FixedAuthNotifier(auth)),
      productoRepositoryProvider.overrideWithValue(products),
      categoriaRepositoryProvider.overrideWithValue(CategoriesFake()),
      proveedorRepositoryProvider.overrideWithValue(SuppliersFake()),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('lista productos renderiza datos, vacio y error', (
    WidgetTester tester,
  ) async {
    final ProductRepositoryFake products = ProductRepositoryFake(<Producto>[
      const Producto(id: 1, nombre: 'Martillo', stockActual: 3),
    ]);
    await tester.pumpWidget(
      buildTestApp(child: const ProductosPage(), products: products),
    );
    await tester.pumpAndSettle();
    expect(find.text('Martillo'), findsOneWidget);

    products.items = <Producto>[];
    await tester.pumpWidget(
      buildTestApp(child: const ProductosPage(), products: products),
    );
    await tester.pumpAndSettle();
    expect(find.text('No hay productos disponibles.'), findsOneWidget);

    products.throwOnList = true;
    await tester.pumpWidget(
      buildTestApp(child: const ProductosPage(), products: products),
    );
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('formulario nuevo valida campos requeridos', (
    WidgetTester tester,
  ) async {
    final ProductRepositoryFake products = ProductRepositoryFake(<Producto>[]);
    await tester.pumpWidget(
      buildTestApp(child: const ProductoFormPage(), products: products),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(find.text('Campo requerido'), findsNWidgets(3));
    expect(products.created, isNull);
  });

  testWidgets('formulario valida, precarga edicion y envia relaciones', (
    WidgetTester tester,
  ) async {
    const Producto product = Producto(
      id: 1,
      nombre: 'Martillo existente',
      stockActual: 5,
      precioCompra: 10,
      precioVenta: 15,
      categoria: Categoria(id: 4, nombre: 'Herramientas'),
      proveedor: Proveedor(id: 8, nombre: 'Acme'),
    );
    final ProductRepositoryFake products = ProductRepositoryFake(<Producto>[
      product,
    ]);
    await tester.pumpWidget(
      buildTestApp(
        child: const ProductoFormPage(id: 1, product: product),
        products: products,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(TextFormField, 'Martillo existente'),
      findsOneWidget,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Herramientas'), findsOneWidget);
    expect(find.text('Acme'), findsOneWidget);

    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(products.updated, isNotNull);
    expect(products.updated!.categoria!.id, 4);
    expect(products.updated!.proveedor!.id, 8);
  });

  testWidgets('eliminar muestra confirmacion y llama al repositorio', (
    WidgetTester tester,
  ) async {
    final ProductRepositoryFake products = ProductRepositoryFake(<Producto>[
      const Producto(id: 9, nombre: 'Taladro'),
    ]);
    await tester.pumpWidget(
      buildTestApp(child: const ProductosPage(), products: products),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Confirmar eliminacion'), findsOneWidget);
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(products.deletedId, 9);
  });
}
