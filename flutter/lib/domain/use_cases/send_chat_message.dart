import '../models/chat_models.dart';
import '../repositories/chat_repository.dart';

class SendChatMessage {
  const SendChatMessage(this._repository);

  final ChatRepository _repository;

  Future<ChatResponse> call(ChatRequest request) =>
      _repository.sendMessage(request);
}
