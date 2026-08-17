// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatSourceDto _$ChatSourceDtoFromJson(Map<String, dynamic> json) =>
    _ChatSourceDto(
      entityType: json['entityType'] as String,
      entityId: (json['entityId'] as num?)?.toInt(),
      excerpt: json['excerpt'] as String?,
      metadata:
          json['metadata'] as Map<String, dynamic>? ??
          const <String, Object?>{},
    );

Map<String, dynamic> _$ChatSourceDtoToJson(_ChatSourceDto instance) =>
    <String, dynamic>{
      'entityType': instance.entityType,
      'entityId': instance.entityId,
      'excerpt': instance.excerpt,
      'metadata': instance.metadata,
    };

_ChatResponseDto _$ChatResponseDtoFromJson(Map<String, dynamic> json) =>
    _ChatResponseDto(
      answer: json['answer'] as String? ?? '',
      sources:
          (json['sources'] as List<dynamic>?)
              ?.map((e) => ChatSourceDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ChatSourceDto>[],
      conversationId: json['conversationId'] as String?,
    );

Map<String, dynamic> _$ChatResponseDtoToJson(_ChatResponseDto instance) =>
    <String, dynamic>{
      'answer': instance.answer,
      'sources': instance.sources,
      'conversationId': instance.conversationId,
    };
