import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ferreplus/domain/models/chat_models.dart';
import 'package:ferreplus/domain/repositories/chat_repository.dart';
import 'package:ferreplus/presentation/features/chat/chat_provider.dart';
import 'package:ferreplus/presentation/features/chat/widgets/chat_sources_accordion.dart';
import 'package:ferreplus/presentation/features/chat/widgets/safe_markdown_renderer.dart';

class FakeChatRepository implements ChatRepository {
  FakeChatRepository({this.response, this.failure});

  ChatResponse? response;
  Object? failure;
  final List<ChatRequest> requests = <ChatRequest>[];

  @override
  Future<ChatResponse> sendMessage(ChatRequest request) async {
    requests.add(request);
    if (failure != null) throw failure!;
    return response ?? const ChatResponse(answer: 'Respuesta');
  }

  @override
  Future<void> rebuildIndex() async {}
}

void main() {
  testWidgets('renderer shows lists, formatting and escaped HTML as text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SafeMarkdownRenderer(
            content: '**Stock**\n- Martillo\n<script>alert(1)</script>',
          ),
        ),
      ),
    );

    expect(find.text('•  '), findsOneWidget);
    expect(find.byType(RichText), findsNWidgets(4));
  });

  testWidgets(
    'sources accordion is hidden without sources and expandable with sources',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatSourcesAccordion(
              sources: <ChatSource>[
                ChatSource(
                  entityType: 'PRODUCTO',
                  entityId: 4,
                  excerpt: 'Bajo stock',
                  metadata: <String, Object?>{'title': 'Martillo'},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Fuentes (1)'), findsOneWidget);
      await tester.tap(find.text('Fuentes (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Martillo'), findsOneWidget);
      expect(find.text('Bajo stock'), findsOneWidget);
    },
  );

  test(
    'notifier preserves conversation id and history after a failure',
    () async {
      final FakeChatRepository repository = FakeChatRepository(
        response: const ChatResponse(answer: 'Primera respuesta'),
      );
      final ProviderContainer container = ProviderContainer(
        overrides: [chatRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container.read(chatProvider.notifier).send('Primera pregunta');
      expect(repository.requests.single.conversationId, isNotNull);
      expect(
        container.read(chatProvider).conversationId,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(container.read(chatProvider).messages, hasLength(2));

      repository.failure = StateError('offline');
      await container.read(chatProvider.notifier).send('Segunda pregunta');
      expect(container.read(chatProvider).messages, hasLength(3));
      expect(container.read(chatProvider).error, isNotNull);
      expect(
        repository.requests.last.conversationId,
        container.read(chatProvider).conversationId,
      );
    },
  );
}
