import 'package:flutter/material.dart';

import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';

class ChatComposer extends StatelessWidget {
  const ChatComposer({
    required this.controller,
    required this.enabled,
    required this.onSend,
    super.key,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.space16,
          AppSpacing.space8,
          AppSpacing.space16,
          keyboardInset > 0 ? keyboardInset : AppSpacing.space12,
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56, maxHeight: 144),
          padding: const EdgeInsets.only(left: AppSpacing.space12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 1000,
                  buildCounter:
                      (
                        BuildContext context, {
                        required int currentLength,
                        required bool isFocused,
                        required int? maxLength,
                      }) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.space4,
                        ),
                        child: Text(
                          '$currentLength/1000',
                          textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    labelText: 'Escribe tu pregunta',
                    hintText: 'Ejemplo: ¿Donde registro un producto?',
                    border: InputBorder.none,
                  ),
                ),
              ),
              Semantics(
                label: 'Enviar pregunta',
                button: true,
                child: IconButton(
                  tooltip: 'Enviar pregunta',
                  onPressed: enabled ? onSend : null,
                  icon: const Icon(Icons.send),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
