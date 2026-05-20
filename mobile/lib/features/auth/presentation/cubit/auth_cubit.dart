import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Cubit авторизації.
/// Керує login, register, перевіркою сесії та logout.
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(const AuthInitial());

  /// Перевіряє, чи користувач уже авторизований.
  Future<void> checkAuthStatus() async {
    emit(const AuthLoading());

    try {
      final hasToken = await _authRepository.hasAccessToken();

      if (!hasToken) {
        emit(const AuthUnauthenticated());
        return;
      }

      final user = await _authRepository.getMe();
      emit(AuthAuthenticated(user));
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  /// Вхід користувача.
Future<void> login({
  required String email,
  required String password,
}) async {
  emit(const AuthLoading());

  try {
    final response = await _authRepository.login(
      email: email,
      password: password,
    );

    emit(AuthAuthenticated(response.user));
  } catch (error) {
    /// Не переводимо одразу в AuthUnauthenticated.
    /// Інакше router може перекинути користувача на інший екран.
    emit(AuthFailure(error.toString().replaceFirst('Exception: ', '')));
  }
}

/// Реєстрація користувача.
Future<void> register({
  required String fullName,
  required String email,
  required String phone,
  required String password,
}) async {
  emit(const AuthLoading());

  try {
    final response = await _authRepository.register(
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
    );

    emit(AuthAuthenticated(response.user));
  } catch (error) {
    /// Залишаємо користувача на поточному екрані й показуємо помилку.
    emit(AuthFailure(error.toString().replaceFirst('Exception: ', '')));
  }
}

/// Вихід із акаунта.
Future<void> logout() async {
  /// Не ставимо AuthLoading, щоб router не кидав користувача на SplashScreen.
  await _authRepository.logout();
  emit(const AuthUnauthenticated());
}
}