import '../models/chat_models.dart';

abstract class ChatRepository {
  Future<ChatResponse> sendMessage(ChatRequest request);
  Future<void> rebuildIndex();
}
