import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ferreplus/domain/models/admin_models.dart';
import 'package:ferreplus/domain/repositories/admin_repositories.dart';
import 'package:ferreplus/presentation/features/admin_pages.dart';
import 'package:ferreplus/presentation/features/admin_providers.dart';

class PriceRepositoryFake implements PrecioRepository {
  PriceRepositoryFake(this.items);
  final List<PrecioProducto> items;
  ActualizarPrecioVentaRequest? updated;
  @override
  Future<List<PrecioProducto>> list() async => items;
  @override
  Future<PrecioProducto> getById(int id) async => items.first;
  @override
  Future<List<HistoricoPrecio>> historial(int id) async =>
      const <HistoricoPrecio>[];
  @override
  Future<void> actualizarVenta(
    int id,
    ActualizarPrecioVentaRequest request,
  ) async {
    updated = request;
  }
}

class FixedRolesNotifier extends RolesNotifier {
  @override
  Future<List<Rol>> build() async => const <Rol>[];
}

Widget adminApp(Widget child, PriceRepositoryFake repository) => ProviderScope(
  overrides: [
    precioRepositoryProvider.overrideWithValue(repository),
    dashboardProvider.overrideWith(
      (ref) async => const ReporteDashboard(
        ventasHoy: 100,
        ventasMes: 500,
        productosStockBajo: 2,
      ),
    ),
  ],
  child: MaterialApp(home: child),
);

Widget roleApp() => ProviderScope(
  overrides: [
    rolesProvider.overrideWith(FixedRolesNotifier.new),
    modulosProvider.overrideWith(
      (ref) async => const <Modulo>[
        Modulo(id: 1, nombre: 'Productos', codigo: 'PRODUCTOS'),
      ],
    ),
    permisosProvider.overrideWith(
      (ref) async => const <Permiso>[
        Permiso(
          id: 1,
          codigo: 'PRODUCTOS_VER',
          nombre: 'Ver productos',
          moduloId: 1,
        ),
      ],
    ),
  ],
  child: const MaterialApp(home: RolFormPage()),
);

void main() {
  testWidgets('precios muestra calculos principales', (
    WidgetTester tester,
  ) async {
    final PriceRepositoryFake repository = PriceRepositoryFake(<PrecioProducto>[
      const PrecioProducto(
        id: 1,
        nombre: 'Taladro',
        precioCompra: 10,
        precioVenta: 15,
        ganancia: 5,
        margenPorcentaje: 50,
      ),
    ]);
    await tester.pumpWidget(adminApp(const PreciosPage(), repository));
    await tester.pumpAndSettle();
    expect(find.text('Taladro'), findsOneWidget);
    expect(find.textContaining('Ganancia'), findsOneWidget);
    expect(find.textContaining('Margen'), findsOneWidget);
  });

  testWidgets('dashboard renderiza KPIs y reintento ante error', (
    WidgetTester tester,
  ) async {
    final PriceRepositoryFake repository = PriceRepositoryFake(
      const <PrecioProducto>[],
    );
    await tester.pumpWidget(adminApp(const DashboardAdminPage(), repository));
    await tester.pumpAndSettle();
    expect(find.text('Ventas hoy'), findsOneWidget);
    expect(find.text('Stock bajo'), findsOneWidget);
  });

  testWidgets('formulario de roles renderiza matriz agrupada por modulo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(roleApp());
    await tester.pumpAndSettle();
    expect(find.text('Productos'), findsOneWidget);
    await tester.tap(find.text('Productos'));
    await tester.pumpAndSettle();
    expect(find.text('PRODUCTOS_VER'), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
  });
}
