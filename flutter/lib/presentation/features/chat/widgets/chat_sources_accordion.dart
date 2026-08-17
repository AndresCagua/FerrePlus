import 'package:flutter/material.dart';

import '../../../../domain/models/chat_models.dart';

class ChatSourcesAccordion extends StatelessWidget {
  const ChatSourcesAccordion({required this.sources, super.key});

  final List<ChatSource> sources;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text('Fuentes (${sources.length})'),
      leading: const Icon(Icons.source_outlined),
      children: sources
          .map(
            (ChatSource source) => ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(_title(source)),
              subtitle: Text(source.excerpt ?? source.entityType),
            ),
          )
          .toList(growable: false),
    );
  }

  String _title(ChatSource source) {
    final Object? title = source.metadata['title'];
    if (title is String && title.trim().isNotEmpty) return title;
    return '${source.entityType} #${source.entityId ?? '-'}';
  }
}
