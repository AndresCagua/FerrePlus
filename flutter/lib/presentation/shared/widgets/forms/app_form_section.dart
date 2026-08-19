import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';

/// Groups related form controls and establishes a consistent vertical rhythm.
class AppFormSection extends StatelessWidget {
  const AppFormSection({
    required this.title,
    required this.children,
    this.spacing = AppSpacing.space16,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.space24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space12),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
        for (int index = 0; index < children.length; index++) ...<Widget>[
          if (index > 0) SizedBox(height: spacing),
          children[index],
        ],
      ],
    ),
  );
}
