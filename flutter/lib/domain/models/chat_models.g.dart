// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatRequest _$ChatRequestFromJson(Map<String, dynamic> json) => _ChatRequest(
  question: json['question'] as String,
  conversationId: json['conversationId'] as String?,
);

Map<String, dynamic> _$ChatRequestToJson(_ChatRequest instance) =>
    <String, dynamic>{
      'question': instance.question,
      'conversationId': instance.conversationId,
    };

_ChatSource _$ChatSourceFromJson(Map<String, dynamic> json) => _ChatSource(
  entityType: json['entityType'] as String,
  entityId: (json['entityId'] as num?)?.toInt(),
  excerpt: json['excerpt'] as String?,
  metadata:
      json['metadata'] as Map<String, dynamic>? ?? const <String, Object?>{},
);

Map<String, dynamic> _$ChatSourceToJson(_ChatSource instance) =>
    <String, dynamic>{
      'entityType': instance.entityType,
      'entityId': instance.entityId,
      'excerpt': instance.excerpt,
      'metadata': instance.metadata,
    };

_ChatResponse _$ChatResponseFromJson(Map<String, dynamic> json) =>
    _ChatResponse(
      answer: json['answer'] as String? ?? '',
      sources:
          (json['sources'] as List<dynamic>?)
              ?.map((e) => ChatSource.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ChatSource>[],
    );

Map<String, dynamic> _$ChatResponseToJson(_ChatResponse instance) =>
    <String, dynamic>{'answer': instance.answer, 'sources': instance.sources};
