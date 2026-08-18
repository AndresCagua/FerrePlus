import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/permission_codes.dart';
import '../../core/providers/auth_providers.dart';
import '../shared/widgets/theme_selector.dart';
import '../theme/app_component_theme.dart';
import 'chat_floating_action_button.dart';

class ShellScaffold extends ConsumerWidget {
  const ShellScaffold({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Set<String> permissions = ref.watch(authNotifierProvider).permisos;
    final List<_Destination> destinations =
        <_Destination>[
              const _Destination(
                'Dashboard',
                '/',
                Icons.dashboard,
                PermissionCodes.dashboard,
                0,
              ),
              const _Destination(
                'Productos',
                '/productos',
                Icons.inventory_2,
                PermissionCodes.productos,
                1,
              ),
              const _Destination(
                'Categorias',
                '/categorias',
                Icons.category,
                PermissionCodes.categorias,
                2,
              ),
              const _Destination(
                'Proveedores',
                '/proveedores',
                Icons.local_shipping,
                PermissionCodes.proveedores,
                3,
              ),
              const _Destination(
                'Clientes',
                '/clientes',
                Icons.person,
                PermissionCodes.clientes,
                4,
              ),
              const _Destination(
                'Ventas',
                '/ventas',
                Icons.point_of_sale,
                PermissionCodes.ventas,
                5,
              ),
              const _Destination(
                'Compras',
                '/compras',
                Icons.shopping_cart,
                PermissionCodes.compras,
                6,
              ),
              const _Destination(
                'Movimientos',
                '/movimientos',
                Icons.swap_vert,
                PermissionCodes.movimientos,
                7,
              ),
              const _Destination(
                'Gastos',
                '/gastos',
                Icons.money_off,
                PermissionCodes.gastos,
                8,
              ),
              const _Destination(
                'Usuarios',
                '/usuarios',
                Icons.people,
                PermissionCodes.usuarios,
                10,
              ),
              const _Destination(
                'Precios',
                '/gestion-precios',
                Icons.sell,
                PermissionCodes.precios,
                9,
              ),
              const _Destination(
                'Roles',
                '/roles',
                Icons.admin_panel_settings,
                PermissionCodes.roles,
                11,
              ),
              const _Destination(
                'Reportes',
                '/reportes',
                Icons.analytics,
                PermissionCodes.reportes,
                12,
              ),
              const _Destination(
                'Logs',
                '/logs',
                Icons.history,
                PermissionCodes.logs,
                13,
              ),
              const _Destination(
                'Chat',
                '/chat',
                Icons.smart_toy,
                PermissionCodes.chat,
                14,
              ),
            ]
            .where(
              (destination) =>
                  destination.permission == null ||
                  permissions.contains(destination.permission),
            )
            .toList();
    final int currentBranch = navigationShell.currentIndex;
    final int selectedDestination = destinations.indexWhere(
      (destination) => destination.branchIndex == currentBranch,
    );
    final AppComponentTheme components =
        Theme.of(context).extension<AppComponentTheme>() ?? AppComponentTheme.standard;
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForBranch(currentBranch)),
        actions: <Widget>[
          Builder(
            builder: (BuildContext drawerContext) => IconButton(
              tooltip: 'Abrir ajustes de tema',
              icon: const Icon(Icons.palette_outlined),
              onPressed: () => Scaffold.of(drawerContext).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: navigationShell,
      floatingActionButton: const ChatFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      endDrawer: Drawer(
        child: SafeArea(
          child: Padding(
            padding: components.cardPadding,
            child: const ThemeSelector(),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedDestination < 0 ? 0 : selectedDestination,
        onDestinationSelected: (int index) => navigationShell.goBranch(
          destinations[index].branchIndex,
          initialLocation: destinations[index].branchIndex == currentBranch,
        ),
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

  String _titleForBranch(int branch) => switch (branch) {
        0 => 'Dashboard',
        1 => 'Productos',
        2 => 'Categorias',
        3 => 'Proveedores',
        4 => 'Clientes',
        5 => 'Ventas',
        6 => 'Compras',
        7 => 'Movimientos',
        8 => 'Gastos',
        9 => 'Precios',
        10 => 'Usuarios',
        11 => 'Roles',
        12 => 'Reportes',
        13 => 'Logs',
        14 => 'Chat',
        _ => 'FerrePlus',
      };
}

class _Destination {
  const _Destination(
    this.label,
    this.path,
    this.icon,
    this.permission,
    this.branchIndex,
  );
  final String label;
  final String path;
  final IconData icon;
  final String? permission;
  final int branchIndex;
}
