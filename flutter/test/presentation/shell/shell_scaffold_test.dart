import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ferreplus/core/providers/auth_providers.dart';
import 'package:ferreplus/domain/models/auth_state.dart';
import 'package:ferreplus/presentation/features/mas/mas_page.dart';
import 'package:ferreplus/presentation/shell/shell_scaffold.dart';

class _FixedAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}

GoRouter _router() => GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    StatefulShellRoute.indexedStack(
      builder:
          (
            BuildContext context,
            GoRouterState state,
            StatefulNavigationShell shell,
          ) => ShellScaffold(navigationShell: shell),
      branches: <StatefulShellBranch>[
        _branch('/', 'Dashboard'),
        _branch('/productos', 'Productos'),
        _branch('/ventas', 'Ventas'),
        _branch('/reportes', 'Reportes'),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/mas',
              builder: (BuildContext context, GoRouterState state) =>
                  const MasPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);

StatefulShellBranch _branch(String path, String label) => StatefulShellBranch(
  routes: <RouteBase>[
    GoRoute(
      path: path,
      builder: (BuildContext context, GoRouterState state) => Text(label),
      routes: <RouteBase>[
        if (path == '/ventas')
          GoRoute(
            path: 'gastos',
            builder: (BuildContext context, GoRouterState state) =>
                const Text('Gastos'),
          ),
      ],
    ),
  ],
);

void main() {
  testWidgets('muestra cinco destinos y el FAB autenticado', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authNotifierProvider.overrideWith(_FixedAuthNotifier.new)],
        child: MaterialApp.router(routerConfig: _router()),
      ),
    );
    await tester.pump();

    expect(find.byType(NavigationDestination), findsNWidgets(5));
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Productos'), findsWidgets);
    expect(find.text('Ventas'), findsWidgets);
    expect(find.text('Reportes'), findsWidgets);
    expect(find.text('Más'), findsWidgets);
    expect(find.byTooltip('Abrir chat'), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
  });

  testWidgets('vuelve a la ruta canonica al tocar la rama activa', (
    tester,
  ) async {
    final GoRouter router = _router();
    router.go('/ventas/gastos');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authNotifierProvider.overrideWith(_FixedAuthNotifier.new)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Ventas').last);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/ventas');
    expect(find.text('Ventas'), findsWidgets);
  });
}
