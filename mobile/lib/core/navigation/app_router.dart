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

import '../../features/pets/presentation/screens/create_pet_screen.dart';
import '../../features/pets/presentation/screens/my_pets_screen.dart';
import '../../features/pets/presentation/screens/pet_details_screen.dart';
import '../../features/qr/presentation/screens/pet_qr_screen.dart';
import '../../features/qr/presentation/screens/public_qr_profile_screen.dart';
import '../../features/lost_reports/presentation/screens/create_lost_report_screen.dart';
import '../../features/lost_reports/presentation/screens/lost_report_details_screen.dart';
import '../../features/lost_reports/presentation/screens/lost_reports_screen.dart';
import '../../features/map_events/presentation/screens/map_screen.dart';

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
      GoRoute(
        path: '/pets',
        builder: (context, state) => const MyPetsScreen(),
      ),
      GoRoute(
        path: '/pets/create',
        builder: (context, state) => const CreatePetScreen(),
      ),
      GoRoute(
        path: '/pets/:id',
        builder: (context, state) {
          final petId = state.pathParameters['id']!;

          return PetDetailsScreen(petId: petId);
        },
      ),
      GoRoute(
        path: '/lost-reports',
        builder: (context, state) => const LostReportsScreen(),
      ),
      GoRoute(
        path: '/lost-reports/create/:petId',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;

          return CreateLostReportScreen(petId: petId);
        },
      ),
      GoRoute(
        path: '/lost-reports/:id',
        builder: (context, state) {
          final reportId = state.pathParameters['id']!;

          return LostReportDetailsScreen(reportId: reportId);
        },
      ),
      GoRoute(
        path: '/pets/:id/qr',
        builder: (context, state) {
          final petId = state.pathParameters['id']!;

          return PetQrScreen(petId: petId);
        },
      ),
      GoRoute(
        path: '/qr-public/:token',
        builder: (context, state) {
          final token = state.pathParameters['token']!;

          return PublicQrProfileScreen(token: token);
        },
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => const MapScreen(),
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