// ignore_for_file: unused_element, unused_import
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ferreplus/core/constants/permission_codes.dart';
import 'package:ferreplus/core/providers/auth_providers.dart';
import 'package:ferreplus/core/routing/app_router.dart';
import 'package:ferreplus/domain/models/admin_models.dart';
import 'package:ferreplus/domain/models/auth_state.dart';
import 'package:ferreplus/domain/models/catalog_models.dart';
import 'package:ferreplus/domain/models/commercial_models.dart';
import 'package:ferreplus/domain/repositories/admin_repositories.dart';
import 'package:ferreplus/domain/repositories/catalog_repositories.dart';
import 'package:ferreplus/domain/repositories/commercial_repositories.dart';
import 'package:ferreplus/presentation/features/admin_pages.dart';
import 'package:ferreplus/presentation/features/admin_providers.dart';
import 'package:ferreplus/presentation/features/catalog_pages.dart';
import 'package:ferreplus/presentation/features/catalog_providers.dart';
import 'package:ferreplus/presentation/features/productos/productos_pages.dart';
import 'package:ferreplus/presentation/features/commercial_pages.dart';
import 'package:ferreplus/presentation/features/commercial_providers.dart';

class _Auth extends AuthNotifier {
  _Auth(this.permissions);
  final Set<String> permissions;

  @override
  AuthState build() =>
      AuthState(status: AuthStatus.authenticated, permisos: permissions);
}

class _UserRepository implements UsuarioRepository {
  _UserRepository(this.user);
  Usuario user;
  final Completer<void> passwordCompleter = Completer<void>();
  final Completer<void> deleteCompleter = Completer<void>();
  UsuarioRequest? updated;
  int createCalls = 0;
  bool failDelete = false;

  @override
  Future<List<Usuario>> list() async => <Usuario>[user];
  @override
  Future<Usuario> getById(int id) async => user;
  @override
  Future<Usuario> me() async => user;
  @override
  Future<Usuario> create(UsuarioRequest request) async {
    createCalls++;
    return user;
  }

  @override
  Future<Usuario> update(int id, UsuarioRequest request) async {
    updated = request;
    return user;
  }

  @override
  Future<void> delete(int id) async {
    await deleteCompleter.future;
    if (failDelete) throw StateError('delete user failed');
  }

  @override
  Future<void> changePassword(int id, CambioPasswordRequest request) async {
    await passwordCompleter.future;
    throw StateError('password failed');
  }
}

class _RoleRepository implements RolRepository {
  _RoleRepository(this.role);
  Rol role;
  final Completer<void> deleteCompleter = Completer<void>();
  RolRequest? updated;
  int? updatedId;
  int createCalls = 0;
  bool failDelete = false;

  @override
  Future<List<Rol>> list() async => <Rol>[role];
  @override
  Future<Rol> getById(int id) async => role;
  @override
  Future<Rol> create(RolRequest request) async {
    createCalls++;
    return role;
  }

  @override
  Future<Rol> update(int id, RolRequest request) async {
    updatedId = id;
    updated = request;
    return role;
  }

  @override
  Future<void> delete(int id) async {
    await deleteCompleter.future;
    if (failDelete) throw StateError('delete role failed');
  }
}

class _FixedRolesNotifier extends RolesNotifier {
  @override
  Future<List<Rol>> build() async => const <Rol>[Rol(id: 2, nombre: 'Admin')];
}

class _CategoryRepository implements CategoriaRepository {
  _CategoryRepository(this.items);
  List<Categoria> items;
  final Completer<void> deleteCompleter = Completer<void>();

  @override
  Future<List<Categoria>> list() async => items;
  @override
  Future<Categoria> getById(int id) async => items.single;
  @override
  Future<Categoria> create(Categoria value) async => value;
  @override
  Future<Categoria> update(int id, Categoria value) async => value;
  @override
  Future<void> delete(int id) async {
    await deleteCompleter.future;
    items = <Categoria>[];
  }
}

class _SupplierRepository implements ProveedorRepository {
  _SupplierRepository(this.items);
  List<Proveedor> items;
  final Completer<void> deleteCompleter = Completer<void>();

  @override
  Future<List<Proveedor>> list() async => items;
  @override
  Future<Proveedor> getById(int id) async => items.single;
  @override
  Future<Proveedor> create(Proveedor value) async => value;
  @override
  Future<Proveedor> update(int id, Proveedor value) async => value;
  @override
  Future<void> delete(int id) async {
    await deleteCompleter.future;
    items = <Proveedor>[];
  }
}

class _ClientRepository implements ClienteRepository {
  _ClientRepository(this.items);
  List<Cliente> items;
  final Completer<void> deleteCompleter = Completer<void>();

  @override
  Future<List<Cliente>> list() async => items;
  @override
  Future<Cliente> getById(int id) async => items.single;
  @override
  Future<Cliente> create(Cliente value) async => value;
  @override
  Future<Cliente> update(int id, Cliente value) async => value;
  @override
  Future<void> delete(int id) async {
    await deleteCompleter.future;
    items = <Cliente>[];
  }
}

class _ProductRepository implements ProductoRepository {
  _ProductRepository(this.items);
  List<Producto> items;
  final Completer<void> deleteCompleter = Completer<void>();

  @override
  Future<List<Producto>> list({String? query, int? categoria}) async => items;
  @override
  Future<Producto> getById(int id) async => items.single;
  @override
  Future<Producto> create(Producto value) async => value;
  @override
  Future<Producto> update(int id, Producto value) async => value;
  @override
  Future<void> delete(int id) async {
    await deleteCompleter.future;
    items = <Producto>[];
  }
}

class _SalesRepository implements VentaRepository {
  _SalesRepository(this.sale);
  final Venta sale;
  final Completer<void> anularCompleter = Completer<void>();
  bool fail = false;
  int anularCalls = 0;

  @override
  Future<List<Venta>> list({
    DateTime? desde,
    DateTime? hasta,
    String? estado,
    int? clienteId,
  }) async => <Venta>[sale];
  @override
  Future<Venta> getById(int id) async => sale;
  @override
  Future<Venta> create(VentaRequest request) async => sale;
  @override
  Future<void> anular(int id) async {
    anularCalls++;
    await anularCompleter.future;
    if (fail) throw StateError('sale failed');
  }

  @override
  Future<List<Venta>> reportePorFecha(DateTime desde, DateTime hasta) async =>
      <Venta>[];
}

class _PurchaseRepository implements CompraRepository {
  _PurchaseRepository(this.purchase);
  final Compra purchase;
  final Completer<void> anularCompleter = Completer<void>();
  bool fail = false;
  int anularCalls = 0;

  @override
  Future<List<Compra>> list({
    DateTime? desde,
    DateTime? hasta,
    String? estado,
    int? proveedorId,
  }) async => <Compra>[purchase];
  @override
  Future<Compra> getById(int id) async => purchase;
  @override
  Future<Compra> create(CompraRequest request) async => purchase;
  @override
  Future<Compra> update(int id, CompraRequest request) async => purchase;
  @override
  Future<void> anular(int id) async {
    anularCalls++;
    await anularCompleter.future;
    if (fail) throw StateError('purchase failed');
  }

  @override
  Future<List<Compra>> reportePorFecha(DateTime desde, DateTime hasta) async =>
      <Compra>[];
}

class _ExpenseRepository implements GastoRepository {
  _ExpenseRepository(this.expense);
  final Gasto expense;
  final Completer<void> deleteCompleter = Completer<void>();
  bool fail = false;

  @override
  Future<List<Gasto>> list() async => <Gasto>[expense];
  @override
  Future<Gasto> getById(int id) async => expense;
  @override
  Future<Gasto> create(GastoRequest request) async => expense;
  @override
  Future<Gasto> update(int id, GastoRequest request) async => expense;
  @override
  Future<void> delete(int id) async {
    await deleteCompleter.future;
    if (fail) throw StateError('expense failed');
  }
}

class _LogRepository implements LogRepository {
  final Completer<LogsEliminados> deleteCompleter = Completer<LogsEliminados>();

  @override
  Future<LogsPage> list({
    int page = 0,
    int size = 20,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    int? usuarioId,
    String? entidad,
    String? accion,
  }) async => const LogsPage(
    content: <Auditoria>[],
    totalElements: 0,
    totalPages: 0,
    number: 0,
    size: 20,
  );

  @override
  Future<List<UsuarioOpcion>> usuarios() async => const <UsuarioOpcion>[];

  @override
  Future<LogsEliminados> deleteRange(DateTime desde, DateTime hasta) =>
      deleteCompleter.future;
}

Widget _routerApp({
  required Set<String> permissions,
  required List<Object?> overrides,
  required ValueChanged<GoRouter> onRouter,
}) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(() => _Auth(permissions)),
    ...overrides,
  ].cast(),
  child: _RouterHost(onRouter: onRouter),
);

class _RouterHost extends ConsumerWidget {
  const _RouterHost({required this.onRouter});
  final ValueChanged<GoRouter> onRouter;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(routerProvider);
    onRouter(router);
    return MaterialApp.router(routerConfig: router);
  }
}

void main() {
  const Usuario user = Usuario(
    id: 7,
    nombre: 'Usuario cargado',
    email: 'loaded@example.com',
    telefono: '555',
    rolId: 2,
  );
  const Rol role = Rol(
    id: 9,
    nombre: 'Rol cargado',
    descripcion: 'Descripcion',
  );
  final Set<String> adminPermissions = <String>{
    PermissionCodes.dashboard,
    PermissionCodes.usuarios,
    PermissionCodes.usuariosEditar,
    PermissionCodes.usuariosEliminar,
    PermissionCodes.roles,
    PermissionCodes.rolesEditar,
    PermissionCodes.rolesEliminar,
  };

  testWidgets('deep link de usuario carga por id y actualiza, no crea', (
    WidgetTester tester,
  ) async {
    final _UserRepository repository = _UserRepository(user);
    late GoRouter router;
    await tester.pumpWidget(
      _routerApp(
        permissions: adminPermissions,
        onRouter: (GoRouter value) => router = value,
        overrides: [
          usuarioRepositoryProvider.overrideWithValue(repository),
          rolesProvider.overrideWith(_FixedRolesNotifier.new),
        ],
      ),
    );
    await tester.pumpAndSettle();
    router.go('/usuarios/7/editar');
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(TextFormField, 'Usuario cargado'),
      findsOneWidget,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(repository.updated, isNotNull);
    expect(repository.createCalls, 0);
  });

  testWidgets('deep link de rol carga por id y actualiza, no crea', (
    WidgetTester tester,
  ) async {
    final _RoleRepository repository = _RoleRepository(role);
    late GoRouter router;
    await tester.pumpWidget(
      _routerApp(
        permissions: adminPermissions,
        onRouter: (GoRouter value) => router = value,
        overrides: [
          rolRepositoryProvider.overrideWithValue(repository),
          modulosProvider.overrideWith((ref) async => const <Modulo>[]),
          permisosProvider.overrideWith((ref) async => const <Permiso>[]),
        ],
      ),
    );
    await tester.pumpAndSettle();
    router.go('/roles/9/editar');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Rol cargado'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(repository.updated, isNotNull);
    expect(repository.updatedId, 9);
    expect(repository.createCalls, 0);
  });

  testWidgets('cambio de contrasena deshabilita el boton y muestra error', (
    WidgetTester tester,
  ) async {
    final _UserRepository repository = _UserRepository(user);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(() => _Auth(adminPermissions)),
          usuarioRepositoryProvider.overrideWithValue(repository),
          rolesProvider.overrideWith(_FixedRolesNotifier.new),
        ],
        child: const MaterialApp(home: UsuarioFormPage(id: 7, usuario: user)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pump();
    await tester.tap(find.text('Cambiar contrasena'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).last, 'new');
    await tester.enterText(
      find
          .byType(TextFormField)
          .at(find.byType(TextFormField).evaluate().length - 2),
      'old',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Cambiar'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    repository.passwordCompleter.complete();
    await tester.pumpAndSettle();
    expect(
      find.text('No se pudo completar la operacion. Intenta nuevamente.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Cambiar'))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'eliminar usuario mantiene confirmacion deshabilitada y navega al completar',
    (WidgetTester tester) async {
      final _UserRepository repository = _UserRepository(user);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => _Auth(adminPermissions)),
            usuarioRepositoryProvider.overrideWithValue(repository),
            rolesProvider.overrideWith(_FixedRolesNotifier.new),
          ],
          child: const MaterialApp(home: UsuarioFormPage(id: 7, usuario: user)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pump();
      await tester.tap(find.text('Eliminar usuario'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      repository.deleteCompleter.complete();
      await tester.pumpAndSettle();
      expect(repository.deleteCompleter.isCompleted, isTrue);
    },
  );

  testWidgets('eliminar rol falla, muestra SnackBar y re habilita', (
    WidgetTester tester,
  ) async {
    final _RoleRepository repository = _RoleRepository(role)..failDelete = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(() => _Auth(adminPermissions)),
          rolRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: RolesPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Eliminar rol'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    repository.deleteCompleter.complete();
    await tester.pumpAndSettle();
    expect(
      find.text('No se pudo completar la operacion. Intenta nuevamente.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Eliminar'))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('catalogos deshabilitan delete concurrente', (
    WidgetTester tester,
  ) async {
    final _CategoryRepository repository = _CategoryRepository(
      const <Categoria>[Categoria(id: 1, nombre: 'Cat')],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            () => _Auth(<String>{PermissionCodes.categoriasEliminar}),
          ),
          categoriaRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: CategoriasPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repository.deleteCompleter.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('precio deshabilita actualizar mientras espera', (
    WidgetTester tester,
  ) async {
    final Completer<void> completer = Completer<void>();
    final PriceRepositoryFake repository = PriceRepositoryFake(
      const <PrecioProducto>[
        PrecioProducto(
          id: 1,
          nombre: 'Precio',
          precioCompra: 1,
          precioVenta: 2,
        ),
      ],
      completer,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            () => _Auth(<String>{PermissionCodes.preciosEditar}),
          ),
          precioRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: PreciosPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Actualizar precio'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(0), '3');
    await tester.enterText(find.byType(TextFormField).at(1), 'ref');
    await tester.tap(find.widgetWithText(FilledButton, 'Actualizar'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('proveedor deshabilita delete durante la mutacion', (
    WidgetTester tester,
  ) async {
    final _SupplierRepository repository = _SupplierRepository(
      const <Proveedor>[Proveedor(id: 1, nombre: 'Proveedor')],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            () => _Auth(<String>{PermissionCodes.proveedoresEliminar}),
          ),
          proveedorRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: ProveedoresPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repository.deleteCompleter.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('cliente deshabilita delete durante la mutacion', (
    WidgetTester tester,
  ) async {
    final _ClientRepository repository = _ClientRepository(const <Cliente>[
      Cliente(id: 1, nombre: 'Cliente'),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            () => _Auth(<String>{PermissionCodes.clientesEliminar}),
          ),
          clienteRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: ClientesPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repository.deleteCompleter.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('producto deshabilita delete durante la mutacion', (
    WidgetTester tester,
  ) async {
    final _ProductRepository repository = _ProductRepository(const <Producto>[
      Producto(id: 1, nombre: 'Producto'),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            () => _Auth(<String>{PermissionCodes.productosEliminar}),
          ),
          productoRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: ProductosListPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repository.deleteCompleter.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('borrado de logs deshabilita el boton durante la mutacion', (
    WidgetTester tester,
  ) async {
    final _LogRepository repository = _LogRepository();
    final ProviderContainer container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(
          () => _Auth(<String>{PermissionCodes.logsEliminar}),
        ),
        logRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LogsPageView()),
      ),
    );
    await tester.pumpAndSettle();
    container.read(logsProvider.notifier)
      ..desde = DateTime(2026, 1, 1)
      ..hasta = DateTime(2026, 1, 2);
    final Future<LogsEliminados> pending = container
        .read(logsProvider.notifier)
        .deleteRange(DateTime(2026, 1, 1), DateTime(2026, 1, 2));
    await tester.pump();
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byTooltip('Borrar por rango'),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNull,
    );
    repository.deleteCompleter.complete(const LogsEliminados(1));
    await pending;
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('anular venta confirma, muestra progreso y navega al completar', (
    WidgetTester tester,
  ) async {
    const Venta sale = Venta(
      id: 1,
      numeroFactura: 'V-001',
      subtotal: 10,
      descuento: 0,
      iva: 1.5,
      total: 11.5,
      estado: 'COMPLETADA',
    );
    final _SalesRepository repository = _SalesRepository(sale);
    late GoRouter router;
    final Set<String> permissions = <String>{
      PermissionCodes.dashboard,
      PermissionCodes.ventas,
      PermissionCodes.ventasEliminar,
    };

    await tester.pumpWidget(
      _routerApp(
        permissions: permissions,
        onRouter: (GoRouter value) => router = value,
        overrides: [ventaRepositoryProvider.overrideWithValue(repository)],
      ),
    );
    await tester.pumpAndSettle();
    router.go('/ventas/1');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Anular venta'));
    await tester.pump();
    expect(find.text('Anular venta'), findsNWidgets(2));
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await tester.pump();
    expect(repository.anularCalls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed,
      isNull,
    );

    repository.anularCompleter.complete();
    for (int i = 0; i < 20 && find.byType(SnackBar).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(repository.anularCalls, 1);
    expect(find.text('Detalle de venta'), findsNothing);
  });

  testWidgets('anular compra falla, muestra SnackBar y re habilita', (
    WidgetTester tester,
  ) async {
    const Compra purchase = Compra(
      id: 1,
      numeroFactura: 'C-001',
      subtotal: 10,
      descuento: 0,
      iva: 1.5,
      total: 11.5,
      estado: 'COMPLETADA',
    );
    final _PurchaseRepository repository = _PurchaseRepository(purchase)
      ..fail = true;
    final Set<String> permissions = <String>{
      PermissionCodes.dashboard,
      PermissionCodes.compras,
      PermissionCodes.comprasEliminar,
    };
    late GoRouter router;

    await tester.pumpWidget(
      _routerApp(
        permissions: permissions,
        onRouter: (GoRouter value) => router = value,
        overrides: [compraRepositoryProvider.overrideWithValue(repository)],
      ),
    );
    await tester.pumpAndSettle();
    router.go('/compras');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.cancel_outlined));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repository.anularCompleter.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(repository.anularCalls, 1);
  });

  testWidgets('eliminar gasto falla, muestra SnackBar y re habilita', (
    WidgetTester tester,
  ) async {
    const Gasto expense = Gasto(
      id: 1,
      descripcion: 'Transporte',
      monto: 20,
      categoria: 'Logistica',
    );
    final _ExpenseRepository repository = _ExpenseRepository(expense)
      ..fail = true;
    final Set<String> permissions = <String>{
      PermissionCodes.dashboard,
      PermissionCodes.gastos,
      PermissionCodes.gastosEliminar,
    };
    late GoRouter router;

    await tester.pumpWidget(
      _routerApp(
        permissions: permissions,
        onRouter: (GoRouter value) => router = value,
        overrides: [gastoRepositoryProvider.overrideWithValue(repository)],
      ),
    );
    await tester.pumpAndSettle();
    router.go('/gastos');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repository.deleteCompleter.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(repository.deleteCompleter.isCompleted, isTrue);
  });
}

class PriceRepositoryFake implements PrecioRepository {
  PriceRepositoryFake(this.items, this.completer);
  final List<PrecioProducto> items;
  final Completer<void> completer;
  @override
  Future<List<PrecioProducto>> list() async => items;
  @override
  Future<PrecioProducto> getById(int id) async => items.first;
  @override
  Future<List<HistoricoPrecio>> historial(int id) async =>
      const <HistoricoPrecio>[];
  @override
  Future<void> actualizarVenta(int id, ActualizarPrecioVentaRequest request) =>
      completer.future;
}
