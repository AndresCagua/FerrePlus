import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../data/services/api_client.dart';
import '../../data/services/token_storage.dart';
import '../../domain/models/auth_state.dart';
import '../../domain/models/login_request.dart';
import '../../domain/repositories/auth_repository.dart';
import 'offline_providers.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(const FlutterSecureStorage());
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final TokenStorage storage = ref.watch(tokenStorageProvider);
  return ApiClient(
    tokenReader: () => storage.cachedToken,
    onUnauthorized: () async {
      await ref.read(offlineCoordinatorProvider).onUnauthorized();
      await ref.read(authNotifierProvider.notifier).logout();
    },
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    dio: ref.watch(apiClientProvider).dio,
    storage: ref.watch(tokenStorageProvider),
  );
});

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    Future<void>.microtask(restoreSession);
    return const AuthState();
  }

  Future<void> restoreSession() async {
    if (state.status != AuthStatus.unknown) return;
    try {
      if (!await _repository.isAuthenticated()) {
        await ref.read(offlineCoordinatorProvider).setCurrentUserId(null);
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      final user = await _repository.getCurrentUser();
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        permisos: user.permisos.toSet(),
      );
      await ref.read(offlineCoordinatorProvider).setCurrentUserId(user.id);
      await ref
          .read(offlineCoordinatorProvider)
          .resumeAfterLogin(userId: user.id);
    } catch (error) {
      await ref.read(offlineCoordinatorProvider).setCurrentUserId(null);
      await _repository.logout();
      state = AuthState(status: AuthStatus.failure, error: error.toString());
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.unknown, error: null);
    try {
      final response = await _repository.login(
        LoginRequest(email: email, password: password),
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        permisos: response.permisos.toSet(),
      );
      await ref
          .read(offlineCoordinatorProvider)
          .setCurrentUserId(response.usuarioId);
      await refreshUser();
      await ref
          .read(offlineCoordinatorProvider)
          .resumeAfterLogin(userId: response.usuarioId);
    } catch (error) {
      state = AuthState(status: AuthStatus.failure, error: error.toString());
    }
  }

  Future<void> refreshUser() async {
    final user = await _repository.getCurrentUser();
    state = AuthState(
      status: AuthStatus.authenticated,
      user: user,
      permisos: user.permisos.toSet(),
    );
    await ref.read(offlineCoordinatorProvider).setCurrentUserId(user.id);
  }

  Future<void> logout() async {
    await _repository.logout();
    await ref.read(offlineCoordinatorProvider).setCurrentUserId(null);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  bool hasPermission(String permission) => state.permisos.contains(permission);
}
