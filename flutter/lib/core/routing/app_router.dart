import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/auth_state.dart';
import '../../presentation/features/auth/login_screen.dart';
import '../../presentation/features/dashboard/dashboard_screen.dart';
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
      final String? permission = routePermissions[state.uri.path];
      if (isAuth && permission != null && !auth.permisos.contains(permission)) return '/';
      return null;
    },
    routes: <RouteBase>[
      GoRoute(path: '/auth', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: <RouteBase>[
          GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
          GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
          ...stubRoutes,
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

final List<GoRoute> stubRoutes = routePermissions.entries.map((entry) => GoRoute(
      path: entry.key,
      builder: (context, state) => PlaceholderScreen(title: _title(entry.key)),
    )).toList(growable: false);

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
