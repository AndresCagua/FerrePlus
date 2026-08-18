import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'chat_floating_action_button.dart';

class ShellScaffold extends ConsumerWidget {
  const ShellScaffold({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const List<_Destination> destinations = <_Destination>[
      _Destination('Dashboard', Icons.dashboard_outlined, 0),
      _Destination('Productos', Icons.inventory_2_outlined, 1),
      _Destination('Ventas', Icons.point_of_sale_outlined, 2),
      _Destination('Reportes', Icons.analytics_outlined, 3),
      _Destination('Más', Icons.more_horiz, 4),
    ];
    final int currentBranch = navigationShell.currentIndex;
    return Scaffold(
      appBar: AppBar(title: Text(_titleForBranch(currentBranch))),
      body: navigationShell,
      floatingActionButton: const ChatFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentBranch,
        onDestinationSelected: (int index) => navigationShell.goBranch(
          destinations[index].branchIndex,
          initialLocation: destinations[index].branchIndex == currentBranch,
        ),
        destinations: destinations
            .map(
              (destination) => NavigationDestination(
                icon: Semantics(
                  label: destination.label,
                  button: true,
                  child: Icon(destination.icon),
                ),
                label: destination.label,
                tooltip: destination.label,
              ),
            )
            .toList(),
      ),
    );
  }

  String _titleForBranch(int branch) => switch (branch) {
    0 => 'Dashboard',
    1 => 'Productos',
    2 => 'Ventas',
    3 => 'Reportes',
    4 => 'Más',
    _ => 'FerrePlus',
  };
}

class _Destination {
  const _Destination(this.label, this.icon, this.branchIndex);
  final String label;
  final IconData icon;
  final int branchIndex;
}
