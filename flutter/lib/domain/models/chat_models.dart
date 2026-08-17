import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_models.freezed.dart';
part 'chat_models.g.dart';

@freezed
abstract class ChatRequest with _$ChatRequest {
  const factory ChatRequest({
    required String question,
    String? conversationId,
  }) = _ChatRequest;

  factory ChatRequest.fromJson(Map<String, Object?> json) =>
      _$ChatRequestFromJson(json);
}

@freezed
abstract class ChatSource with _$ChatSource {
  const factory ChatSource({
    required String entityType,
    int? entityId,
    String? excerpt,
    @Default(<String, Object?>{}) Map<String, Object?> metadata,
  }) = _ChatSource;

  factory ChatSource.fromJson(Map<String, Object?> json) =>
      _$ChatSourceFromJson(json);
}

@freezed
abstract class ChatResponse with _$ChatResponse {
  const factory ChatResponse({
    @Default('') String answer,
    @Default(<ChatSource>[]) List<ChatSource> sources,
    String? conversationId,
  }) = _ChatResponse;

  factory ChatResponse.fromJson(Map<String, Object?> json) =>
      _$ChatResponseFromJson(json);
}

@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String role,
    required String content,
    @Default(<ChatSource>[]) List<ChatSource> sources,
    required DateTime timestamp,
  }) = _ChatMessage;
}
