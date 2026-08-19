import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ferreplus/core/constants/permission_codes.dart';
import 'package:ferreplus/core/providers/auth_providers.dart';
import 'package:ferreplus/core/routing/app_router.dart';
import 'package:ferreplus/domain/models/auth_state.dart';

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this.value);
  final AuthState value;

  @override
  AuthState build() => value;
}

void main() {
  test('expone las rutas canonicas de las cinco ramas', () {
    expect(branchInitialRoutes, <int, String>{
      0: '/',
      1: '/productos',
      2: '/ventas',
      3: '/reportes',
      4: '/mas',
    });
  });

  test('conserva permisos de todas las rutas secundarias', () {
    expect(routePermissions['/categorias'], PermissionCodes.categorias);
    expect(routePermissions['/proveedores'], PermissionCodes.proveedores);
    expect(routePermissions['/clientes'], PermissionCodes.clientes);
    expect(routePermissions['/compras'], PermissionCodes.compras);
    expect(routePermissions['/movimientos'], PermissionCodes.movimientos);
    expect(routePermissions['/gastos'], PermissionCodes.gastos);
    expect(routePermissions['/gestion-precios'], PermissionCodes.precios);
    expect(routePermissions['/usuarios'], PermissionCodes.usuarios);
    expect(routePermissions['/roles'], PermissionCodes.roles);
    expect(routePermissions['/logs'], PermissionCodes.logs);
  });

  test('resuelve el deep link de compras con su permiso', () {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(
          () => _FixedAuthNotifier(
            const AuthState(
              status: AuthStatus.authenticated,
              permisos: <String>{PermissionCodes.compras},
            ),
          ),
        ),
      ],
    );
    final router = container.read(routerProvider);
    router.go('/compras');
    expect(router.routeInformationProvider.value.uri.path, '/compras');
    container.dispose();
  });
}
