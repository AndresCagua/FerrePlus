import 'package:flutter/material.dart';

class PermissionVisibility extends StatelessWidget {
  const PermissionVisibility({required this.allowed, required this.child, super.key});
  final bool allowed;
  final Widget child;

  @override
  Widget build(BuildContext context) => allowed ? child : const SizedBox.shrink();
}
