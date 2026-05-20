import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
/// Створення маршрутизатора застосунку.
GoRouter createAppRouter(AuthCubit authCubit) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
  final authState = authCubit.state;

  final location = state.matchedLocation;

  final isAuthRoute = location == '/login' || location == '/register';
  final isSplash = location == '/splash';

  if (authState is AuthLoading || authState is AuthInitial) {
    return isSplash ? null : '/splash';
  }

  if (authState is AuthFailure) {
    return null;
  }

  if (authState is AuthUnauthenticated) {
    return isAuthRoute ? null : '/login';
  }

  if (authState is AuthAuthenticated) {
    if (isSplash || isAuthRoute) {
      return '/home';
    }
  }

  return null;
},
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
}

/// Маленький адаптер, щоб GoRouter міг слухати stream Cubit.
/// Так, доводиться писати цей місточок, бо фреймворки люблять “майже сумісність”.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}