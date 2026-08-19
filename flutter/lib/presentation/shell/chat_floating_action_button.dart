import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../core/providers/auth_providers.dart';
import '../../domain/models/auth_state.dart';

/// FAB de chat arrastrable.
///
/// Envuelve el contenido del shell (la navegación) en un [Stack] y coloca el
/// FAB encima. El usuario puede moverlo libremente con el dedo para que no
/// tape contenido; queda donde lo suelta y nunca sale de los límites de la
/// pantalla (margen de [_margin]). Estado de UI local, no lógica de negocio:
/// por eso usa `StatefulWidget`.
class DraggableChatFab extends StatefulWidget {
  const DraggableChatFab({required this.child, super.key});

  final Widget child;

  @override
  State<DraggableChatFab> createState() => _DraggableChatFabState();
}

class _DraggableChatFabState extends State<DraggableChatFab> {
  static const double _fabSize = 56;
  static const double _margin = 16;

  /// Desplazamiento desde la esquina inferior derecha.
  Offset _offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxDx = constraints.maxWidth - _fabSize - _margin;
        final double maxDy = constraints.maxHeight - _fabSize - _margin;
        final double dx = _offset.dx.clamp(0.0, maxDx);
        final double dy = _offset.dy.clamp(0.0, maxDy);
        return Stack(
          children: <Widget>[
            widget.child,
            Positioned(
              right: _margin + dx,
              bottom: _margin + dy,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (DragUpdateDetails details) {
                  setState(() {
                    // right/bottom crecen al arrastrar hacia arriba-izquierda
                    // (delta negativo), por eso se resta el delta.
                    _offset = Offset(
                      (_offset.dx - details.delta.dx).clamp(0.0, maxDx),
                      (_offset.dy - details.delta.dy).clamp(0.0, maxDy),
                    );
                  });
                },
                child: const ChatFloatingActionButton(),
              ),
            ),
          ],
        );
      },
    );
  }
}

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

    final String currentPath = _currentPath(context);
    final bool isChatOpen = currentPath == '/chat';
    final String label = isChatOpen ? 'Cerrar chat' : 'Abrir chat';

    return Semantics(
      label: label,
      button: true,
      child: FloatingActionButton(
        onPressed: () => _toggleChat(context, ref, isChatOpen, currentPath),
        tooltip: label,
        child: Icon(isChatOpen ? Icons.close : Icons.chat_bubble_outline),
      ),
    );
  }

  void _toggleChat(
    BuildContext context,
    WidgetRef ref,
    bool isChatOpen,
    String currentPath,
  ) {
    if (!isChatOpen) {
      ref.read(chatPreviousLocationProvider.notifier).remember(currentPath);
      context.go('/chat');
      return;
    }

    final String previousLocation =
        ref.read(chatPreviousLocationProvider) ?? '/';
    ref.read(chatPreviousLocationProvider.notifier).clear();
    context.go(previousLocation);
  }
}

String _currentPath(BuildContext context) {
  try {
    return GoRouterState.of(context).uri.path;
  } on GoError {
    return '/';
  }
}
