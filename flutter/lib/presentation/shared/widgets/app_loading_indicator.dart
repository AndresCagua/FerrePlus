import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({this.message = 'Cargando', this.showSkeleton = false, super.key});
  final String message;
  final bool showSkeleton;

  @override
  Widget build(BuildContext context) {
    if (showSkeleton) {
      return Semantics(label: message, liveRegion: true, child: const _LoadingSkeleton());
    }
    return Semantics(
      label: message,
      liveRegion: true,
      child: const Padding(
        padding: EdgeInsets.all(AppSpacing.space24),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(AppSpacing.space16),
        child: Center(child: CircularProgressIndicator()),
      );
}
