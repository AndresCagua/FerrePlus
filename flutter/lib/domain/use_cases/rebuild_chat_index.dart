import '../repositories/chat_repository.dart';

class RebuildChatIndex {
  const RebuildChatIndex(this._repository);

  final ChatRepository _repository;

  Future<void> call() => _repository.rebuildIndex();
}
