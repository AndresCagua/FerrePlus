import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ferreplus/domain/models/login_request.dart';
import 'package:ferreplus/domain/models/login_response.dart';
import 'package:ferreplus/domain/models/usuario.dart';
import 'package:ferreplus/domain/repositories/auth_repository.dart';
import 'package:ferreplus/presentation/features/auth/initial_admin_page.dart';

class _FakeAuthRepository implements AuthRepository {
  bool registered = false;

  @override
  Future<Usuario> register(String email, String password, String nombre) async {
    registered = true;
    return Usuario(id: 1, nombre: nombre, email: email);
  }

  @override
  Future<LoginResponse> login(LoginRequest request) =>
      throw UnimplementedError();
  @override
  Future<Usuario> getCurrentUser() => throw UnimplementedError();
  @override
  Future<void> logout() async {}
  @override
  Future<bool> isAuthenticated() async => false;
  @override
  Future<bool> hasPermission(String permission) async => false;
}

void main() {
  testWidgets('validates and submits initial admin registration', (
    WidgetTester tester,
  ) async {
    final _FakeAuthRepository repository = _FakeAuthRepository();
    final GoRouter router = GoRouter(
      initialLocation: '/registro',
      routes: <RouteBase>[
        GoRoute(
          path: '/registro',
          builder: (BuildContext context, GoRouterState state) =>
              InitialAdminPage(repository: repository),
        ),
        GoRoute(
          path: '/auth',
          builder: (BuildContext context, GoRouterState state) =>
              const Text('Login'),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(find.text('Registrar administrador'), findsOneWidget);
    await tester.tap(find.text('Registrar'));
    await tester.pump();
    expect(find.text('Ingresa el nombre'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Ana Admin');
    await tester.enterText(find.byType(TextFormField).at(1), 'ana@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'secret123');
    await tester.enterText(find.byType(TextFormField).at(3), 'secret123');
    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();

    expect(repository.registered, isTrue);
    expect(find.text('Login'), findsOneWidget);
  });
}
