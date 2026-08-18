import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/admin_models.dart';
import '../../domain/models/auth_state.dart';
import '../../domain/models/catalog_models.dart';
import '../../presentation/features/admin_pages.dart';
import '../../presentation/features/auth/initial_admin_page.dart';
import '../../presentation/features/auth/login_screen.dart';
import '../../presentation/features/catalog_pages.dart';
import '../../presentation/features/chat/pages/chat_page.dart';
import '../../presentation/features/commercial_pages.dart';
import '../../presentation/features/dashboard/dashboard_screen.dart';
import '../../presentation/features/productos/productos_pages.dart';
import '../../presentation/shell/shell_scaffold.dart';
import '../constants/permission_codes.dart';
import '../providers/auth_providers.dart';

final routerProvider = Provider<GoRouter>((Ref ref) {
  final RouterRefresh refresh = RouterRefresh(ref);
  ref.onDispose(refresh.dispose);
  return GoRouter(
    initialLocation: '/auth',
    refreshListenable: refresh,
    redirect: (BuildContext context, GoRouterState state) {
      final AuthState auth = ref.read(authNotifierProvider);
      if (auth.status == AuthStatus.unknown) return null;
      final bool isAuthenticated = auth.status == AuthStatus.authenticated;
      final bool isPublicRoute = <String>{
        '/auth',
        '/auth/registro',
      }.contains(state.uri.path);
      if (!isAuthenticated && !isPublicRoute) return '/auth';
      if (isAuthenticated && isPublicRoute) return '/';
      if (isAuthenticated && state.uri.path == '/sin-acceso') return null;
      final String? permission = _permissionFor(state.uri.path);
      if (isAuthenticated &&
          permission != null &&
          !auth.permisos.contains(permission)) {
        return _fallbackLocation(auth);
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/auth',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/registro',
        builder: (BuildContext context, GoRouterState state) =>
            InitialAdminPage(repository: ref.read(authRepositoryProvider)),
      ),
      GoRoute(
        path: '/sin-acceso',
        builder: (BuildContext context, GoRouterState state) =>
            const _NoPermissionPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) => ShellScaffold(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          _branch(<GoRoute>[
            GoRoute(
              path: '/',
              builder: (BuildContext context, GoRouterState state) =>
                  const DashboardScreen(),
            ),
            GoRoute(
              path: '/dashboard',
              builder: (BuildContext context, GoRouterState state) =>
                  const DashboardScreen(),
            ),
          ]),
          _branch(_productRoutes()),
          _branch(_categoryRoutes()),
          _branch(_supplierRoutes()),
          _branch(_customerRoutes()),
          _branch(_salesRoutes()),
          _branch(_purchaseRoutes()),
          _branch(_movementRoutes()),
          _branch(_expenseRoutes()),
          _branch(_priceRoutes()),
          _branch(_userRoutes()),
          _branch(_roleRoutes()),
          _branch(<GoRoute>[
            GoRoute(
              path: '/reportes',
              builder: (BuildContext context, GoRouterState state) =>
                  const ReportesPage(),
            ),
            GoRoute(
              path: '/reportes/ventas',
              builder: (BuildContext context, GoRouterState state) =>
                  const ReporteVentasPage(),
            ),
            GoRoute(
              path: '/reportes/inventario',
              builder: (BuildContext context, GoRouterState state) =>
                  const ReporteDetallePage(kind: 'inventario'),
            ),
            GoRoute(
              path: '/reportes/movimientos',
              builder: (BuildContext context, GoRouterState state) =>
                  const ReporteDetallePage(kind: 'movimientos'),
            ),
          ]),
          _branch(<GoRoute>[
            GoRoute(
              path: '/logs',
              builder: (BuildContext context, GoRouterState state) =>
                  const LogsPageView(),
            ),
          ]),
          _branch(<GoRoute>[
            GoRoute(
              path: '/chat',
              builder: (BuildContext context, GoRouterState state) =>
                  const ChatPage(),
            ),
          ]),
        ],
      ),
    ],
  );
});

StatefulShellBranch _branch(List<GoRoute> routes) =>
    StatefulShellBranch(routes: routes);

List<GoRoute> _productRoutes() => <GoRoute>[
  GoRoute(
    path: '/productos',
    builder: (BuildContext context, GoRouterState state) =>
        const ProductosListPage(),
    routes: <GoRoute>[
      GoRoute(
        path: 'nuevo',
        builder: (BuildContext context, GoRouterState state) =>
            const ProductoFormPage(),
      ),
      GoRoute(
        path: ':id/editar',
        builder: (BuildContext context, GoRouterState state) =>
            ProductoFormPage(
              id: int.parse(state.pathParameters['id']!),
              product: state.extra is Producto
                  ? state.extra! as Producto
                  : null,
            ),
      ),
    ],
  ),
];

List<GoRoute> _categoryRoutes() => <GoRoute>[
  GoRoute(
    path: '/categorias',
    builder: (BuildContext context, GoRouterState state) =>
        const CategoriasPage(),
    routes: <GoRoute>[
      GoRoute(
        path: 'nuevo',
        builder: (BuildContext context, GoRouterState state) =>
            const CatalogFormPage(kind: CatalogKind.categorias),
      ),
      GoRoute(
        path: ':id/editar',
        builder: (BuildContext context, GoRouterState state) => CatalogFormPage(
          kind: CatalogKind.categorias,
          id: int.parse(state.pathParameters['id']!),
          item: state.extra,
        ),
      ),
    ],
  ),
];

List<GoRoute> _supplierRoutes() => <GoRoute>[
  GoRoute(
    path: '/proveedores',
    builder: (BuildContext context, GoRouterState state) =>
        const ProveedoresPage(),
    routes: <GoRoute>[
      GoRoute(
        path: 'nuevo',
        builder: (BuildContext context, GoRouterState state) =>
            const CatalogFormPage(kind: CatalogKind.proveedores),
      ),
      GoRoute(
        path: ':id/editar',
        builder: (BuildContext context, GoRouterState state) => CatalogFormPage(
          kind: CatalogKind.proveedores,
          id: int.parse(state.pathParameters['id']!),
          item: state.extra,
        ),
      ),
    ],
  ),
];

List<GoRoute> _customerRoutes() => <GoRoute>[
  GoRoute(
    path: '/clientes',
    builder: (BuildContext context, GoRouterState state) =>
        const ClientesPage(),
    routes: <GoRoute>[
      GoRoute(
        path: 'nuevo',
        builder: (BuildContext context, GoRouterState state) =>
            const CatalogFormPage(kind: CatalogKind.clientes),
      ),
      GoRoute(
        path: ':id/editar',
        builder: (BuildContext context, GoRouterState state) => CatalogFormPage(
          kind: CatalogKind.clientes,
          id: int.parse(state.pathParameters['id']!),
          item: state.extra,
        ),
      ),
    ],
  ),
];

List<GoRoute> _salesRoutes() => <GoRoute>[
  GoRoute(
    path: '/ventas',
    builder: (BuildContext context, GoRouterState state) => const VentasPage(),
    routes: <GoRoute>[
      GoRoute(
        path: 'nuevo',
        builder: (BuildContext context, GoRouterState state) =>
            const VentaFormPage(),
      ),
      GoRoute(
        path: 'reportes',
        builder: (BuildContext context, GoRouterState state) =>
            const CommercialReportPage(sales: true),
      ),
      GoRoute(
        path: ':id',
        builder: (BuildContext context, GoRouterState state) =>
            VentaDetailPage(id: int.parse(state.pathParameters['id']!)),
      ),
    ],
  ),
];

List<GoRoute> _purchaseRoutes() => <GoRoute>[
  GoRoute(
    path: '/compras',
    builder: (BuildContext context, GoRouterState state) => const ComprasPage(),
    routes: <GoRoute>[
      GoRoute(
        path: 'nuevo',
        builder: (BuildContext context, GoRouterState state) =>
            const CompraFormPage(),
      ),
      GoRoute(
        path: 'reportes',
        builder: (BuildContext context, GoRouterState state) =>
            const CommercialReportPage(sales: false),
      ),
      GoRoute(
        path: ':id/editar',
        builder: (BuildContext context, GoRouterState state) =>
            CompraFormPage(id: int.parse(state.pathParameters['id']!)),
      ),
    ],
  ),
];

List<GoRoute> _movementRoutes() => <GoRoute>[
  GoRoute(
    path: '/movimientos',
    builder: (BuildContext context, GoRouterState state) =>
        const MovimientosPage(),
    routes: <GoRoute>[
      GoRoute(
        path: 'nuevo',
        builder: (BuildContext context, GoRouterState state) =>
            const MovimientoFormPage(),
      ),
    ],
  ),
];

List<GoRoute> _expenseRoutes() => <GoRoute>[
  GoRoute(
    path: '/gastos',
    builder: (BuildContext context, GoRouterState state) => const GastosPage(),
    routes: <GoRoute>[
      GoRoute(
        path: 'nuevo',
        builder: (BuildContext context, GoRouterState state) =>
            const GastoFormPage(),
      ),
      GoRoute(
        path: ':id/editar',
        builder: (BuildContext context, GoRouterState state) =>
            GastoFormPage(id: int.parse(state.pathParameters['id']!)),
      ),
    ],
  ),
];

List<GoRoute> _priceRoutes() => <GoRoute>[
  GoRoute(
    path: '/gestion-precios',
    builder: (BuildContext context, GoRouterState state) => const PreciosPage(),
    routes: <GoRoute>[
      GoRoute(
        path: ':id/historial',
        builder: (BuildContext context, GoRouterState state) =>
            PrecioHistorialPage(
              id: int.parse(state.pathParameters['id']!),
              precio: state.extra is PrecioProducto
                  ? state.extra! as PrecioProducto
                  : null,
            ),
      ),
    ],
  ),
];

List<GoRoute> _userRoutes() => <GoRoute>[
  GoRoute(
    path: '/usuarios',
    builder: (BuildContext context, GoRouterState state) =>
        const UsuariosPage(),
    routes: <GoRoute>[
      GoRoute(
        path: 'nuevo',
        builder: (BuildContext context, GoRouterState state) =>
            const UsuarioFormPage(),
      ),
      GoRoute(
        path: ':id/editar',
        builder: (BuildContext context, GoRouterState state) => UsuarioFormPage(
          id: int.parse(state.pathParameters['id']!),
          usuario: state.extra is Usuario ? state.extra! as Usuario : null,
        ),
      ),
    ],
  ),
];

List<GoRoute> _roleRoutes() => <GoRoute>[
  GoRoute(
    path: '/roles',
    builder: (BuildContext context, GoRouterState state) => const RolesPage(),
    routes: <GoRoute>[
      GoRoute(
        path: 'nuevo',
        builder: (BuildContext context, GoRouterState state) =>
            const RolFormPage(),
      ),
      GoRoute(
        path: ':id/editar',
        builder: (BuildContext context, GoRouterState state) => RolFormPage(
          id: int.parse(state.pathParameters['id']!),
          rol: state.extra is Rol ? state.extra! as Rol : null,
        ),
      ),
    ],
  ),
];

final Map<String, String> routePermissions = <String, String>{
  '/': PermissionCodes.dashboard,
  '/dashboard': PermissionCodes.dashboard,
  '/productos': PermissionCodes.productos,
  '/categorias': PermissionCodes.categorias,
  '/proveedores': PermissionCodes.proveedores,
  '/clientes': PermissionCodes.clientes,
  '/ventas': PermissionCodes.ventas,
  '/compras': PermissionCodes.compras,
  '/movimientos': PermissionCodes.movimientos,
  '/gastos': PermissionCodes.gastos,
  '/gestion-precios': PermissionCodes.precios,
  '/usuarios': PermissionCodes.usuarios,
  '/roles': PermissionCodes.roles,
  '/reportes': PermissionCodes.reportes,
  '/logs': PermissionCodes.logs,
};

String? _permissionFor(String path) {
  final String? mutationPermission = _mutationPermissionFor(path);
  if (mutationPermission != null) return mutationPermission;
  if (routePermissions.containsKey(path)) return routePermissions[path];
  for (final MapEntry<String, String> entry in routePermissions.entries) {
    if (path.startsWith('${entry.key}/')) return entry.value;
  }
  return null;
}

String? _mutationPermissionFor(String path) {
  const Map<String, String> createRoutes = <String, String>{
    '/productos/nuevo': PermissionCodes.productosCrear,
    '/categorias/nuevo': PermissionCodes.categoriasCrear,
    '/proveedores/nuevo': PermissionCodes.proveedoresCrear,
    '/clientes/nuevo': PermissionCodes.clientesCrear,
    '/ventas/nuevo': PermissionCodes.ventasCrear,
    '/compras/nuevo': PermissionCodes.comprasCrear,
    '/movimientos/nuevo': PermissionCodes.movimientosCrear,
    '/gastos/nuevo': PermissionCodes.gastosCrear,
    '/usuarios/nuevo': PermissionCodes.usuariosCrear,
    '/roles/nuevo': PermissionCodes.rolesCrear,
  };
  if (createRoutes.containsKey(path)) return createRoutes[path];

  const Map<String, String> editPrefixes = <String, String>{
    '/productos/': PermissionCodes.productosEditar,
    '/categorias/': PermissionCodes.categoriasEditar,
    '/proveedores/': PermissionCodes.proveedoresEditar,
    '/clientes/': PermissionCodes.clientesEditar,
    '/compras/': PermissionCodes.comprasEditar,
    '/gastos/': PermissionCodes.gastosEditar,
    '/usuarios/': PermissionCodes.usuariosEditar,
    '/roles/': PermissionCodes.rolesEditar,
  };
  for (final MapEntry<String, String> entry in editPrefixes.entries) {
    if (path.startsWith(entry.key) && path.endsWith('/editar')) {
      return entry.value;
    }
  }
  return null;
}

String _fallbackLocation(AuthState auth) {
  if (auth.permisos.contains(PermissionCodes.dashboard)) return '/';
  for (final MapEntry<String, String> entry in routePermissions.entries) {
    if (entry.key != '/' &&
        entry.key != '/dashboard' &&
        auth.permisos.contains(entry.value)) {
      return entry.key;
    }
  }
  return '/sin-acceso';
}

class _NoPermissionPage extends ConsumerWidget {
  const _NoPermissionPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Sin acceso')),
    body: Center(
      child: FilledButton.icon(
        onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
        icon: const Icon(Icons.logout),
        label: const Text('Cerrar sesion'),
      ),
    ),
  );
}

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
