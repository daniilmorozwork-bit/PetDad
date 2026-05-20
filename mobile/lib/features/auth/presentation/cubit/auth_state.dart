import 'package:equatable/equatable.dart';

import '../../data/models/user_model.dart';

/// Базовий стан авторизації.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Початковий стан.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Перевірка токена / запит до backend.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Користувач авторизований.
class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// Користувач не авторизований.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Помилка авторизації.
class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}