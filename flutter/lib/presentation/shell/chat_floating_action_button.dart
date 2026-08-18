import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_providers.dart';
import '../../domain/models/auth_state.dart';

class ChatFloatingActionButton extends ConsumerWidget {
  const ChatFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // El backend expone /api/chat con @PreAuthorize("isAuthenticated()").
    // Cualquier usuario autenticado puede usar el chat (igual que la web).
    final bool isAuthenticated = ref.watch(
      authNotifierProvider.select(
        (auth) => auth.status == AuthStatus.authenticated,
      ),
    );
    if (!isAuthenticated) return const SizedBox.shrink();

    return Semantics(
      label: 'Abrir chat',
      button: true,
      child: FloatingActionButton(
        onPressed: () => context.go('/chat'),
        tooltip: 'Abrir chat',
        child: const Icon(Icons.chat_bubble_outline),
      ),
    );
  }
}
