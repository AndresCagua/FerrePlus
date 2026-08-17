import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_providers.dart';
import '../../../data/repositories/chat_repository_impl.dart';
import '../../../domain/models/chat_models.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../domain/use_cases/rebuild_chat_index.dart';
import '../../../domain/use_cases/send_chat_message.dart';

final chatRepositoryProvider = Provider<ChatRepository>(
  (Ref ref) => ChatRepositoryImpl(ref.watch(apiClientProvider).dio),
);

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);

class ChatState {
  const ChatState({
    this.messages = const <ChatMessage>[],
    this.conversationId,
    this.isSending = false,
    this.isRebuildingIndex = false,
    this.error,
  });

  final List<ChatMessage> messages;
  final String? conversationId;
  final bool isSending;
  final bool isRebuildingIndex;
  final String? error;

  ChatState copyWith({
    List<ChatMessage>? messages,
    String? conversationId,
    bool? isSending,
    bool? isRebuildingIndex,
    String? error,
    bool clearError = false,
  }) => ChatState(
    messages: messages ?? this.messages,
    conversationId: conversationId ?? this.conversationId,
    isSending: isSending ?? this.isSending,
    isRebuildingIndex: isRebuildingIndex ?? this.isRebuildingIndex,
    error: clearError ? null : error ?? this.error,
  );
}

class ChatNotifier extends Notifier<ChatState> {
  late final SendChatMessage _sendMessage;
  late final RebuildChatIndex _rebuildIndex;

  @override
  ChatState build() {
    final ChatRepository repository = ref.watch(chatRepositoryProvider);
    _sendMessage = SendChatMessage(repository);
    _rebuildIndex = RebuildChatIndex(repository);
    return const ChatState();
  }

  Future<void> send(String question) async {
    final String cleanQuestion = question.trim();
    if (cleanQuestion.isEmpty || state.isSending) return;

    final String conversationId = state.conversationId ?? _newConversationId();
    final ChatMessage userMessage = ChatMessage(
      role: 'user',
      content: cleanQuestion,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      messages: <ChatMessage>[...state.messages, userMessage],
      conversationId: conversationId,
      isSending: true,
      clearError: true,
    );

    try {
      final ChatResponse response = await _sendMessage(
        ChatRequest(question: cleanQuestion, conversationId: conversationId),
      );
      final String answer = response.answer.trim().isEmpty
          ? 'No hay una respuesta disponible para esta consulta.'
          : response.answer;
      final String effectiveConversationId =
          response.conversationId ?? conversationId;
      final ChatMessage assistantMessage = ChatMessage(
        role: 'assistant',
        content: answer,
        sources: response.sources,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: <ChatMessage>[...state.messages, assistantMessage],
        conversationId: effectiveConversationId,
        isSending: false,
      );
    } catch (error) {
      state = state.copyWith(
        isSending: false,
        error:
            'No fue posible obtener una respuesta. Verifica tu conexion e intenta nuevamente.',
      );
    }
  }

  Future<void> rebuildIndex() async {
    if (state.isRebuildingIndex) return;
    state = state.copyWith(isRebuildingIndex: true, clearError: true);
    try {
      await _rebuildIndex();
      state = state.copyWith(isRebuildingIndex: false);
    } catch (error) {
      state = state.copyWith(
        isRebuildingIndex: false,
        error: 'No fue posible reconstruir el indice. Intenta nuevamente.',
      );
    }
  }

  void restartConversation() => state = const ChatState();

  void clearError() => state = state.copyWith(clearError: true);

  String _newConversationId() =>
      'mobile-${DateTime.now().microsecondsSinceEpoch}';
}
