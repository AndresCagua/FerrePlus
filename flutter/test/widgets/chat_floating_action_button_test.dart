import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ferreplus/core/providers/auth_providers.dart';
import 'package:ferreplus/domain/models/auth_state.dart';
import 'package:ferreplus/domain/models/chat_models.dart';
import 'package:ferreplus/domain/repositories/chat_repository.dart';
import 'package:ferreplus/presentation/features/chat/chat_provider.dart';
import 'package:ferreplus/presentation/features/chat/pages/chat_page.dart';
import 'package:ferreplus/presentation/shell/chat_floating_action_button.dart';

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this.authState);

  final AuthState authState;

  @override
  AuthState build() => authState;
}

class _ChatRepositoryFake implements ChatRepository {
  @override
  Future<ChatResponse> sendMessage(ChatRequest request) async =>
      const ChatResponse(answer: 'Respuesta');

  @override
  Future<void> rebuildIndex() async {}
}

Widget _buildTestApp(AuthState authState) {
  final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) => const Scaffold(
          body: Text('Inicio'),
          floatingActionButton: ChatFloatingActionButton(),
        ),
      ),
      GoRoute(
        path: '/chat',
        builder: (BuildContext context, GoRouterState state) => const Scaffold(
          body: ChatPage(),
          floatingActionButton: ChatFloatingActionButton(),
        ),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(() => _FixedAuthNotifier(authState)),
      chatRepositoryProvider.overrideWithValue(_ChatRepositoryFake()),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Widget _buildDraggableTestApp(AuthState authState) {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(() => _FixedAuthNotifier(authState)),
      chatRepositoryProvider.overrideWithValue(_ChatRepositoryFake()),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: DraggableChatFab(
          child: SizedBox.expand(child: Text('Contenido')),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('muestra el FAB con permiso de chat', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(
        const AuthState(
          status: AuthStatus.authenticated,
          permisos: <String>{'CHAT_VER'},
        ),
      ),
    );

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byTooltip('Abrir chat'), findsOneWidget);
  });

  testWidgets('muestra el FAB para cualquier usuario autenticado sin permiso', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(const AuthState(status: AuthStatus.authenticated)),
    );

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byTooltip('Abrir chat'), findsOneWidget);
  });

  testWidgets('oculta el FAB para usuario no autenticado', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(const AuthState(status: AuthStatus.unauthenticated)),
    );

    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('el FAB navega a la pantalla de chat', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(
        const AuthState(
          status: AuthStatus.authenticated,
          permisos: <String>{'CHAT_VER'},
        ),
      ),
    );

    await tester.tap(find.byTooltip('Abrir chat'));
    await tester.pumpAndSettle();

    expect(find.text('Asistente FerrePlus'), findsOneWidget);
  });

  testWidgets('el FAB funciona como toggle y vuelve a la ruta previa', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(
        const AuthState(
          status: AuthStatus.authenticated,
          permisos: <String>{'CHAT_VER'},
        ),
      ),
    );

    await tester.tap(find.byTooltip('Abrir chat'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Cerrar chat'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar chat'));
    await tester.pumpAndSettle();

    expect(find.text('Inicio'), findsOneWidget);
    expect(find.byTooltip('Abrir chat'), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
  });

  testWidgets('el FAB de chat se puede arrastrar libremente', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildDraggableTestApp(const AuthState(status: AuthStatus.authenticated)),
    );

    final Finder fab = find.byType(FloatingActionButton);
    final Offset inicio = tester.getTopLeft(fab);

    // Arrastra hacia arriba-izquierda: el FAB debe moverse con el dedo.
    await tester.drag(fab, const Offset(-80, -120));
    await tester.pumpAndSettle();

    final Offset movido = tester.getTopLeft(fab);
    expect(movido.dx, lessThan(inicio.dx));
    expect(movido.dy, lessThan(inicio.dy));
  });

  testWidgets('el FAB de chat respeta los limites de la pantalla', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildDraggableTestApp(const AuthState(status: AuthStatus.authenticated)),
    );

    final Finder fab = find.byType(FloatingActionButton);

    // Intenta arrastrar muy lejos: no debe salirse del area visible.
    await tester.drag(fab, const Offset(-4000, -4000));
    await tester.pumpAndSettle();

    final Rect area = tester.getRect(fab);
    final Size pantalla = tester.getSize(find.byType(MaterialApp));
    expect(area.left, greaterThanOrEqualTo(0));
    expect(area.top, greaterThanOrEqualTo(0));
    expect(area.right, lessThanOrEqualTo(pantalla.width));
    expect(area.bottom, lessThanOrEqualTo(pantalla.height));
  });
}
