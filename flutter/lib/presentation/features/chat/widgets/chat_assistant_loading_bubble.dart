import 'package:flutter/material.dart';

import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';

class ChatAssistantLoadingBubble extends StatefulWidget {
  const ChatAssistantLoadingBubble({super.key});

  @override
  State<ChatAssistantLoadingBubble> createState() =>
      _ChatAssistantLoadingBubbleState();
}

class _ChatAssistantLoadingBubbleState extends State<ChatAssistantLoadingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool reducedMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      width: double.infinity,
      child: FractionallySizedBox(
        widthFactor: .85,
        alignment: Alignment.centerLeft,
        child: Semantics(
          label: 'Consultando al asistente',
          liveRegion: true,
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.space12),
            padding: const EdgeInsets.all(AppSpacing.space16),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: reducedMotion
                ? const Text('Consultando...')
                : AnimatedBuilder(
                    animation: _controller,
                    builder: (BuildContext context, Widget? child) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text('Consultando'),
                        const SizedBox(width: AppSpacing.space4),
                        Text('.' * ((_controller.value * 3).floor() + 1)),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
