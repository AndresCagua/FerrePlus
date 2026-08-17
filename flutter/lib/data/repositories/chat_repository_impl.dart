import 'package:dio/dio.dart';

import '../../core/constants/api_paths.dart';
import '../../core/errors/failure_mapper.dart';
import '../../domain/models/chat_models.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/chat_response_dto.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<ChatResponse> sendMessage(ChatRequest request) async {
    try {
      final Response<Object?> response = await _dio.post<Object?>(
        ApiPaths.chat,
        data: request.toJson(),
      );
      final Map<String, Object?> body = Map<String, Object?>.from(
        response.data! as Map<Object?, Object?>,
      );
      final ChatResponseDto dto = ChatResponseDto.fromJson(body);
      return ChatResponse(
        answer: dto.answer,
        conversationId: dto.conversationId,
        sources: dto.sources
            .map(
              (ChatSourceDto source) => ChatSource(
                entityType: source.entityType,
                entityId: source.entityId,
                excerpt: source.excerpt,
                metadata: source.metadata,
              ),
            )
            .toList(growable: false),
      );
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }

  @override
  Future<void> rebuildIndex() async {
    try {
      await _dio.post<Object?>(ApiPaths.chatIndexRebuild);
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }
}
