import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/auth_state.dart';
import '../../presentation/features/auth/login_screen.dart';
import '../../presentation/features/dashboard/dashboard_screen.dart';
import '../../presentation/features/catalog_pages.dart';
import '../../presentation/features/productos/productos_pages.dart';
import '../../domain/models/catalog_models.dart';
import '../../presentation/shell/shell_scaffold.dart';
import '../constants/permission_codes.dart';
import '../providers/auth_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final RouterRefresh refresh = RouterRefresh(ref);
  ref.onDispose(refresh.dispose);
  return GoRouter(
    initialLocation: '/auth',
    refreshListenable: refresh,
    redirect: (BuildContext context, GoRouterState state) {
      final AuthState auth = ref.read(authNotifierProvider);
      if (auth.status == AuthStatus.unknown) return null;
      final bool isAuth = auth.status == AuthStatus.authenticated;
      if (!isAuth && state.uri.path != '/auth') return '/auth';
      if (isAuth && state.uri.path == '/auth') return '/';
      final Iterable<String> nestedPermissions = routePermissions.entries
          .where((entry) => state.uri.path.startsWith('${entry.key}/'))
          .map((entry) => entry.value);
      final String? permission =
          routePermissions[state.uri.path] ??
          (nestedPermissions.isEmpty ? null : nestedPermissions.first);
      if (isAuth && permission != null && !auth.permisos.contains(permission)) {
        return '/';
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(path: '/auth', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/productos',
            builder: (context, state) => const ProductosListPage(),
            routes: <RouteBase>[
              GoRoute(
                path: 'nuevo',
                builder: (context, state) => const ProductoFormPage(),
              ),
              GoRoute(
                path: ':id/editar',
                builder: (context, state) => ProductoFormPage(
                  id: int.parse(state.pathParameters['id']!),
                  product: state.extra is Producto
                      ? state.extra! as Producto
                      : null,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/categorias',
            builder: (context, state) => const CategoriasPage(),
            routes: <RouteBase>[
              GoRoute(
                path: 'nuevo',
                builder: (context, state) =>
                    const CatalogFormPage(kind: CatalogKind.categorias),
              ),
              GoRoute(
                path: ':id/editar',
                builder: (context, state) => CatalogFormPage(
                  kind: CatalogKind.categorias,
                  id: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/proveedores',
            builder: (context, state) => const ProveedoresPage(),
            routes: <RouteBase>[
              GoRoute(
                path: 'nuevo',
                builder: (context, state) =>
                    const CatalogFormPage(kind: CatalogKind.proveedores),
              ),
              GoRoute(
                path: ':id/editar',
                builder: (context, state) => CatalogFormPage(
                  kind: CatalogKind.proveedores,
                  id: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/clientes',
            builder: (context, state) => const ClientesPage(),
            routes: <RouteBase>[
              GoRoute(
                path: 'nuevo',
                builder: (context, state) =>
                    const CatalogFormPage(kind: CatalogKind.clientes),
              ),
              GoRoute(
                path: ':id/editar',
                builder: (context, state) => CatalogFormPage(
                  kind: CatalogKind.clientes,
                  id: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          ...stubRoutes.where(
            (GoRoute route) => !const <String>{
              '/productos',
              '/categorias',
              '/proveedores',
              '/clientes',
            }.contains(route.path),
          ),
        ],
      ),
    ],
  );
});

final Map<String, String> routePermissions = <String, String>{
  '/productos': PermissionCodes.productos,
  '/categorias': PermissionCodes.categorias,
  '/proveedores': PermissionCodes.proveedores,
  '/clientes': PermissionCodes.clientes,
  '/ventas': PermissionCodes.ventas,
  '/compras': PermissionCodes.compras,
  '/movimientos': PermissionCodes.movimientos,
  '/gastos': PermissionCodes.gastos,
  '/precios': PermissionCodes.precios,
  '/usuarios': PermissionCodes.usuarios,
  '/roles': PermissionCodes.roles,
  '/reportes': PermissionCodes.reportes,
  '/logs': PermissionCodes.logs,
  '/chat': PermissionCodes.chat,
};

final List<GoRoute> stubRoutes = routePermissions.entries
    .map(
      (entry) => GoRoute(
        path: entry.key,
        builder: (context, state) =>
            PlaceholderScreen(title: _title(entry.key)),
      ),
    )
    .toList(growable: false);

String _title(String path) => path.substring(1).replaceAll('-', ' ');

class RouterRefresh extends ChangeNotifier {
  RouterRefresh(this._ref) {
    _subscription = _ref.listen<AuthState>(
      authNotifierProvider,
      (AuthState? previous, AuthState next) => notifyListeners(),
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
