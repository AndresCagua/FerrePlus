import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ferreplus/core/providers/auth_providers.dart';
import 'package:ferreplus/domain/models/auth_state.dart';
import 'package:ferreplus/presentation/features/mas/mas_page.dart';
import 'package:ferreplus/presentation/theme/app_theme.dart';

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this.value);
  final AuthState value;

  @override
  AuthState build() => value;
}

Widget _masApp(Set<String> permissions, {List<RouteBase>? routes}) {
  final GoRouter router = GoRouter(
    initialLocation: '/mas',
    routes:
        routes ??
        <RouteBase>[
          GoRoute(
            path: '/mas',
            builder: (BuildContext context, GoRouterState state) =>
                const MasPage(),
          ),
        ],
  );
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(
        () => _FixedAuthNotifier(
          AuthState(status: AuthStatus.authenticated, permisos: permissions),
        ),
      ),
    ],
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  );
}

void main() {
  testWidgets('muestra secciones y selector de tema con permisos', (
    tester,
  ) async {
    await tester.pumpWidget(
      _masApp(<String>{
        'COMPRAS_VER',
        'MOVIMIENTOS_VER',
        'GASTOS_VER',
        'CATEGORIAS_VER',
        'PROVEEDORES_VER',
        'CLIENTES_VER',
        'PRECIOS_VER',
        'USUARIOS_VER',
        'ROLES_VER',
        'LOGS_VER',
        'CHAT_VER',
      }),
    );
    for (final String section in <String>[
      'OPERACIONES',
      'CATALOGOS',
      'ADMINISTRACION',
      'SISTEMA',
    ]) {
      await tester.scrollUntilVisible(find.text(section), 400);
      expect(find.text(section), findsOneWidget);
    }
    expect(find.text('Seguir sistema'), findsOneWidget);
    expect(find.text('Logs'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Cerrar sesion'), findsOneWidget);
  });

  testWidgets('oculta items y secciones sin permiso', (tester) async {
    await tester.pumpWidget(_masApp(<String>{'COMPRAS_VER'}));
    await tester.scrollUntilVisible(find.text('SISTEMA'), 400);

    expect(find.text('Compras'), findsOneWidget);
    expect(find.text('ADMINISTRACION'), findsNothing);
    expect(find.text('Usuarios'), findsNothing);
    expect(find.text('Logs'), findsNothing);
    expect(find.text('Seguir sistema'), findsOneWidget);
  });

  testWidgets('navega a la ruta canonica desde un item', (tester) async {
    await tester.pumpWidget(
      _masApp(
        <String>{'COMPRAS_VER'},
        routes: <RouteBase>[
          GoRoute(
            path: '/mas',
            builder: (BuildContext context, GoRouterState state) =>
                const MasPage(),
          ),
          GoRoute(
            path: '/compras',
            builder: (BuildContext context, GoRouterState state) =>
                const Text('Compras destino'),
          ),
        ],
      ),
    );

    await tester.tap(find.text('Compras'));
    await tester.pumpAndSettle();
    expect(find.text('Compras destino'), findsOneWidget);
  });
}
