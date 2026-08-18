import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ferreplus/core/providers/auth_providers.dart';
import 'package:ferreplus/domain/models/auth_state.dart';
import 'package:ferreplus/domain/models/catalog_models.dart';
import 'package:ferreplus/domain/models/commercial_models.dart';
import 'package:ferreplus/domain/repositories/catalog_repositories.dart';
import 'package:ferreplus/domain/repositories/commercial_repositories.dart';
import 'package:ferreplus/presentation/features/catalog_pages.dart';
import 'package:ferreplus/presentation/features/catalog_providers.dart';
import 'package:ferreplus/presentation/features/commercial_providers.dart';
import 'package:ferreplus/core/routing/app_router.dart';

class _AuthenticatedWithoutPermissions extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}

class _CategoryEditorAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    status: AuthStatus.authenticated,
    permisos: <String>{'CATEGORIAS_CREAR'},
  );
}

class _SalesWithDates implements VentaRepository {
  @override
  Future<List<Venta>> list({
    DateTime? desde,
    DateTime? hasta,
    String? estado,
    int? clienteId,
  }) async => <Venta>[
    Venta(
      id: 1,
      subtotal: 1,
      descuento: 0,
      iva: 0,
      total: 1,
      fechaCreacion: DateTime(2026, 8, 15, 23, 59),
    ),
    Venta(
      id: 2,
      subtotal: 1,
      descuento: 0,
      iva: 0,
      total: 1,
      fechaCreacion: DateTime(2026, 8, 16),
    ),
  ];

  @override
  Future<Venta> getById(int id) => throw UnimplementedError();
  @override
  Future<Venta> create(VentaRequest request) => throw UnimplementedError();
  @override
  Future<void> anular(int id) => throw UnimplementedError();
  @override
  Future<List<Venta>> reportePorFecha(DateTime desde, DateTime hasta) =>
      throw UnimplementedError();
}

class _DelayedCategories implements CategoriaRepository {
  final Completer<Categoria> createCompleter = Completer<Categoria>();
  int createCalls = 0;

  @override
  Future<List<Categoria>> list() async => <Categoria>[];
  @override
  Future<Categoria> getById(int id) => throw UnimplementedError();
  @override
  Future<Categoria> create(Categoria value) {
    createCalls++;
    return createCompleter.future;
  }

  @override
  Future<Categoria> update(int id, Categoria value) =>
      throw UnimplementedError();
  @override
  Future<void> delete(int id) => throw UnimplementedError();
}

void main() {
  test(
    'el filtro hasta incluye registros posteriores a medianoche del mismo dia',
    () async {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          ventaRepositoryProvider.overrideWithValue(_SalesWithDates()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(ventasProvider.future);
      await container
          .read(ventasProvider.notifier)
          .filter(to: DateTime(2026, 8, 15));

      expect(
        container.read(ventasProvider).value!.map((Venta item) => item.id),
        <int>[1],
      );
    },
  );

  testWidgets('un usuario sin permisos termina en sin acceso', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            _AuthenticatedWithoutPermissions.new,
          ),
        ],
        child: const _RouterHost(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sin acceso'), findsOneWidget);
  });

  testWidgets('el formulario deshabilita guardar mientras espera la mutacion', (
    WidgetTester tester,
  ) async {
    final _DelayedCategories repository = _DelayedCategories();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_CategoryEditorAuth.new),
          categoriaRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: CatalogFormPage(kind: CatalogKind.categorias),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField).first, 'Herramientas');
    await tester.tap(find.text('Guardar'));
    await tester.pump();

    final FilledButton button = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(button.onPressed, isNull);
    expect(repository.createCalls, 1);
    repository.createCompleter.complete(
      const Categoria(id: 1, nombre: 'Herramientas'),
    );
  });
}

class _RouterHost extends ConsumerWidget {
  const _RouterHost();

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      MaterialApp.router(routerConfig: ref.watch(routerProvider));
}
