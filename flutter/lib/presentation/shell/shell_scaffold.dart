import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/permission_codes.dart';
import '../../core/providers/auth_providers.dart';

class ShellScaffold extends ConsumerWidget {
  const ShellScaffold({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Set<String> permissions = ref.watch(authNotifierProvider).permisos;
    final List<_Destination> destinations =
        <_Destination>[
              const _Destination('Dashboard', '/', Icons.dashboard, null),
              const _Destination(
                'Productos',
                '/productos',
                Icons.inventory_2,
                PermissionCodes.productos,
              ),
              const _Destination(
                'Categorias',
                '/categorias',
                Icons.category,
                PermissionCodes.categorias,
              ),
              const _Destination(
                'Proveedores',
                '/proveedores',
                Icons.local_shipping,
                PermissionCodes.proveedores,
              ),
              const _Destination(
                'Clientes',
                '/clientes',
                Icons.person,
                PermissionCodes.clientes,
              ),
              const _Destination(
                'Ventas',
                '/ventas',
                Icons.point_of_sale,
                PermissionCodes.ventas,
              ),
              const _Destination(
                'Compras',
                '/compras',
                Icons.shopping_cart,
                PermissionCodes.compras,
              ),
              const _Destination(
                'Movimientos',
                '/movimientos',
                Icons.swap_vert,
                PermissionCodes.movimientos,
              ),
              const _Destination(
                'Gastos',
                '/gastos',
                Icons.money_off,
                PermissionCodes.gastos,
              ),
              const _Destination(
                'Usuarios',
                '/usuarios',
                Icons.people,
                PermissionCodes.usuarios,
              ),
              const _Destination(
                'Precios',
                '/gestion-precios',
                Icons.sell,
                PermissionCodes.precios,
              ),
              const _Destination(
                'Roles',
                '/roles',
                Icons.admin_panel_settings,
                PermissionCodes.roles,
              ),
              const _Destination(
                'Reportes',
                '/reportes',
                Icons.analytics,
                PermissionCodes.reportes,
              ),
              const _Destination(
                'Logs',
                '/logs',
                Icons.history,
                PermissionCodes.logs,
              ),
              const _Destination(
                'Chat',
                '/chat',
                Icons.smart_toy,
                PermissionCodes.chat,
              ),
            ]
            .where(
              (destination) =>
                  destination.permission == null ||
                  permissions.contains(destination.permission),
            )
            .toList();
    final String location = GoRouterState.of(context).uri.path;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(destinations, location),
        onDestinationSelected: (int index) =>
            context.go(destinations[index].path),
        destinations: destinations
            .map(
              (destination) => NavigationDestination(
                icon: Icon(destination.icon),
                label: destination.label,
              ),
            )
            .toList(),
      ),
    );
  }

  int _selectedIndex(List<_Destination> destinations, String location) {
    final int index = destinations.indexWhere(
      (destination) => destination.path == location,
    );
    return index < 0 ? 0 : index;
  }
}

class _Destination {
  const _Destination(this.label, this.path, this.icon, this.permission);
  final String label;
  final String path;
  final IconData icon;
  final String? permission;
}
