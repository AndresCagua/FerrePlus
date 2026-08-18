import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';
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
  Widget build(BuildContext context) {
    final Color base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final Color highlight = Theme.of(context).colorScheme.surfaceContainerHigh;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _SkeletonBox(width: 96, height: 96, base: base, highlight: highlight),
          const SizedBox(height: AppSpacing.space16),
          _SkeletonLine(width: 200, base: base, highlight: highlight),
          const SizedBox(height: AppSpacing.space8),
          _SkeletonLine(width: 160, base: base, highlight: highlight),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, required this.base, required this.highlight});
  final double width;
  final Color base;
  final Color highlight;

  @override
  Widget build(BuildContext context) {
    return _SkeletonBox(
      width: width,
      height: 12,
      radius: AppRadius.small,
      base: base,
      highlight: highlight,
    );
  }
}

class _SkeletonBox extends StatefulWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.base,
    required this.highlight,
    this.radius = AppRadius.medium,
  });
  final double width;
  final double height;
  final double radius;
  final Color base;
  final Color highlight;

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            color: Color.lerp(widget.base, widget.highlight, _controller.value),
          ),
        );
      },
    );
  }
}