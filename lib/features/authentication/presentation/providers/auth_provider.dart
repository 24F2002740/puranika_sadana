import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/session_service.dart';
import '../../data/services/auth_service.dart';
import '../../domain/models/auth_user.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final sessionServiceProvider = Provider<SessionService>((ref) => SessionService());

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthUser?>>((ref) {
  return AuthNotifier(
    ref.watch(authServiceProvider),
    ref.watch(sessionServiceProvider),
  );
});

class AuthNotifier extends StateNotifier<AsyncValue<AuthUser?>> {
  final AuthService _authService;
  final SessionService _sessionService;

  AuthNotifier(this._authService, this._sessionService) : super(const AsyncValue.data(null));

  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();

    final user = await _authService.login(email, password);

    if (user != null) {
      await _sessionService.saveLoginSession(true);
      state = AsyncValue.data(user);
      return true;
    }

    state = const AsyncValue.data(null);
    return false;
  }

  Future<void> logout() async {
    await _authService.logout();
    await _sessionService.clearSession();
    state = const AsyncValue.data(null);
  }
}
