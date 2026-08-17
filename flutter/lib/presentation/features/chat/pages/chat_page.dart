import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/permission_codes.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../domain/models/chat_models.dart';
import '../chat_provider.dart';
import '../widgets/chat_sources_accordion.dart';
import '../widgets/safe_markdown_renderer.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final String question = _controller.text.trim();
    if (question.isEmpty) return;
    _controller.clear();
    await ref.read(chatProvider.notifier).send(question);
  }

  @override
  Widget build(BuildContext context) {
    final ChatState chat = ref.watch(chatProvider);
    final bool canRebuild = ref
        .watch(authNotifierProvider)
        .permisos
        .contains(PermissionCodes.chatIndexRebuild);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente FerrePlus'),
        actions: <Widget>[
          if (canRebuild)
            Semantics(
              label: 'Reconstruir indice del chat',
              button: true,
              child: IconButton(
                tooltip: 'Reconstruir indice',
                onPressed: chat.isRebuildingIndex ? null : _confirmRebuild,
                icon: chat.isRebuildingIndex
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
              ),
            ),
          Semantics(
            label: 'Reiniciar conversacion',
            button: true,
            child: IconButton(
              tooltip: 'Reiniciar conversacion',
              onPressed: chat.messages.isEmpty
                  ? null
                  : () => ref.read(chatProvider.notifier).restartConversation(),
              icon: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (chat.error != null)
            MaterialBanner(
              content: Text(chat.error!),
              leading: const Icon(Icons.error_outline),
              actions: <Widget>[
                TextButton(
                  onPressed: () => ref.read(chatProvider.notifier).clearError(),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          Expanded(child: _messages(context, chat)),
          _composer(context, chat),
        ],
      ),
    );
  }

  Widget _messages(BuildContext context, ChatState chat) {
    if (chat.messages.isEmpty && !chat.isSending) {
      return const Center(child: Text('Escribe una pregunta para comenzar.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: chat.messages.length + (chat.isSending ? 1 : 0),
      itemBuilder: (BuildContext context, int index) {
        if (index == chat.messages.length) {
          return const ListTile(
            leading: CircularProgressIndicator(),
            title: Text('Consultando al asistente...'),
          );
        }
        return _messageBubble(context, chat.messages[index]);
      },
    );
  }

  Widget _messageBubble(BuildContext context, ChatMessage message) {
    final bool isUser = message.role == 'user';
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? colors.primaryContainer : colors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              isUser ? 'Tu' : 'Asistente',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            isUser
                ? Text(message.content)
                : SafeMarkdownRenderer(content: message.content),
            ChatSourcesAccordion(sources: message.sources),
          ],
        ),
      ),
    );
  }

  Widget _composer(BuildContext context, ChatState chat) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _controller,
              maxLength: 1000,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Escribe tu pregunta',
                hintText: 'Ejemplo: ¿Donde registro un producto?',
                border: OutlineInputBorder(),
              ),
              enabled: !chat.isSending,
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            label: 'Enviar pregunta',
            button: true,
            child: IconButton.filled(
              tooltip: 'Enviar pregunta',
              onPressed: chat.isSending ? null : _send,
              icon: const Icon(Icons.send),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _confirmRebuild() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Reconstruir indice'),
        content: const Text('Esta operacion puede tardar. ¿Deseas continuar?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reconstruir'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(chatProvider.notifier).rebuildIndex();
    }
  }
}

typedef ChatScreen = ChatPage;
