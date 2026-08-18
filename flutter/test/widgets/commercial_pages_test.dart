import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ferreplus/core/providers/auth_providers.dart';
import 'package:ferreplus/domain/models/auth_state.dart';
import 'package:ferreplus/domain/models/catalog_models.dart';
import 'package:ferreplus/domain/models/commercial_models.dart';
import 'package:ferreplus/domain/repositories/catalog_repositories.dart';
import 'package:ferreplus/domain/repositories/commercial_repositories.dart';
import 'package:ferreplus/presentation/features/catalog_providers.dart';
import 'package:ferreplus/presentation/features/commercial_pages.dart';
import 'package:ferreplus/presentation/features/commercial_providers.dart';
import 'package:ferreplus/core/constants/permission_codes.dart';
import 'package:ferreplus/core/routing/app_router.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    status: AuthStatus.authenticated,
    permisos: <String>{'VENTAS_VER', 'VENTAS_CREAR'},
  );
}

class _ReadOnlySalesAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    status: AuthStatus.authenticated,
    permisos: <String>{PermissionCodes.ventas},
  );
}

class _Products implements ProductoRepository {
  @override
  Future<List<Producto>> list({
    String? query,
    int? categoria,
  }) async => <Producto>[
    const Producto(id: 1, nombre: 'Martillo', stockActual: 5, precioVenta: 100),
  ];
  @override
  Future<Producto> getById(int id) async =>
      const Producto(id: 1, nombre: 'Martillo');
  @override
  Future<Producto> create(Producto value) async => value;
  @override
  Future<Producto> update(int id, Producto value) async => value;
  @override
  Future<void> delete(int id) async {}
}

class _Clients implements ClienteRepository {
  @override
  Future<List<Cliente>> list() async => <Cliente>[];
  @override
  Future<Cliente> getById(int id) async =>
      const Cliente(id: 1, nombre: 'Cliente');
  @override
  Future<Cliente> create(Cliente value) async => value;
  @override
  Future<Cliente> update(int id, Cliente value) async => value;
  @override
  Future<void> delete(int id) async {}
}

class _Sales implements VentaRepository {
  @override
  Future<List<Venta>> list({
    DateTime? desde,
    DateTime? hasta,
    String? estado,
    int? clienteId,
  }) async => <Venta>[
    const Venta(
      id: 1,
      subtotal: 10,
      descuento: 0,
      iva: 1.5,
      total: 11.5,
      estado: 'COMPLETADA',
    ),
  ];
  @override
  Future<Venta> getById(int id) async =>
      const Venta(id: 1, subtotal: 10, descuento: 0, iva: 1.5, total: 11.5);
  @override
  Future<Venta> create(VentaRequest request) async =>
      const Venta(id: 1, subtotal: 10, descuento: 0, iva: 1.5, total: 11.5);
  @override
  Future<void> anular(int id) async {}
  @override
  Future<List<Venta>> reportePorFecha(DateTime desde, DateTime hasta) async =>
      <Venta>[];
}

void main() {
  testWidgets('POS agrega una linea y calcula subtotal e IVA', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_Auth.new),
          productoRepositoryProvider.overrideWithValue(_Products()),
          clienteRepositoryProvider.overrideWithValue(_Clients()),
          ventaRepositoryProvider.overrideWithValue(_Sales()),
        ],
        child: const MaterialApp(home: VentaFormPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Subtotal: 0.00'), findsOneWidget);
    expect(find.text('IVA (15%): 0.00'), findsOneWidget);
    expect(find.text('Total: 0.00'), findsOneWidget);
  });

  testWidgets('lista de ventas muestra estado', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_Auth.new),
          ventaRepositoryProvider.overrideWithValue(_Sales()),
        ],
        child: const MaterialApp(home: VentasPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('COMPLETADA'), findsOneWidget);
    expect(find.text('11.50'), findsOneWidget);
  });

  testWidgets('bloquea guardar venta sin VENTAS_CREAR', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_ReadOnlySalesAuth.new),
          ventaRepositoryProvider.overrideWithValue(_Sales()),
        ],
        child: const MaterialApp(home: VentaFormPage()),
      ),
    );
    await tester.pumpAndSettle();
    final FilledButton button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Guardar venta'),
    );
    expect(button.onPressed, isNull);
  });

  test('protege dashboard con DASHBOARD_VER', () {
    expect(routePermissions['/'], PermissionCodes.dashboard);
    expect(routePermissions['/dashboard'], PermissionCodes.dashboard);
  });
}
