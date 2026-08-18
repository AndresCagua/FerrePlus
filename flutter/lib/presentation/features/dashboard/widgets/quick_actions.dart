import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/permission_codes.dart';
import '../../../../core/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_spacing.dart';

class QuickActions extends ConsumerWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Set<String> permissions = ref.watch(authNotifierProvider).permisos;
    final List<_QuickAction> actions =
        <_QuickAction>[
              const _QuickAction(
                '+ Nueva venta',
                '/ventas/nuevo',
                PermissionCodes.ventasCrear,
                Icons.point_of_sale,
              ),
              const _QuickAction(
                '+ Nuevo producto',
                '/productos/nuevo',
                PermissionCodes.productosCrear,
                Icons.inventory_2,
              ),
              const _QuickAction(
                '+ Registrar gasto',
                '/gastos/nuevo',
                PermissionCodes.gastosCrear,
                Icons.receipt_long,
              ),
              const _QuickAction(
                '+ Registrar compra',
                '/compras/nuevo',
                PermissionCodes.comprasCrear,
                Icons.shopping_cart,
              ),
            ]
            .where(
              (_QuickAction action) => permissions.contains(action.permission),
            )
            .toList();
    if (actions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Acciones rápidas', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.space8),
        Wrap(
          spacing: AppSpacing.space8,
          runSpacing: AppSpacing.space8,
          children: actions
              .map(
                (action) => ActionChip(
                  avatar: Icon(action.icon),
                  label: Text(action.label),
                  onPressed: () => context.go(action.route),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _QuickAction {
  const _QuickAction(this.label, this.route, this.permission, this.icon);
  final String label;
  final String route;
  final String permission;
  final IconData icon;
}
