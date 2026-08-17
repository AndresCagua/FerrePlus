import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_response_dto.freezed.dart';
part 'chat_response_dto.g.dart';

@freezed
abstract class ChatSourceDto with _$ChatSourceDto {
  const factory ChatSourceDto({
    required String entityType,
    int? entityId,
    String? excerpt,
    @Default(<String, Object?>{}) Map<String, Object?> metadata,
  }) = _ChatSourceDto;

  factory ChatSourceDto.fromJson(Map<String, Object?> json) =>
      _$ChatSourceDtoFromJson(json);
}

@freezed
abstract class ChatResponseDto with _$ChatResponseDto {
  const factory ChatResponseDto({
    @Default('') String answer,
    @Default(<ChatSourceDto>[]) List<ChatSourceDto> sources,
    String? conversationId,
  }) = _ChatResponseDto;

  factory ChatResponseDto.fromJson(Map<String, Object?> json) =>
      _$ChatResponseDtoFromJson(json);
}
