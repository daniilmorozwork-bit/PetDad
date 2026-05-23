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
import '../../features/sightings/presentation/screens/create_sighting_screen.dart';
import '../../features/sightings/presentation/screens/sighting_details_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/pets/presentation/screens/edit_pet_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

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
  final isPublicQrRoute = location.startsWith('/qr-public/');

  /// Публічний профіль за QR доступний без авторизації.
  if (isPublicQrRoute) {
    return null;
  }

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
        path: '/pets/:id/edit',
        builder: (context, state) {
          final petId = state.pathParameters['id']!;

          return EditPetScreen(petId: petId);
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
      GoRoute(
        path: '/lost-reports/:id/sightings/create',
        builder: (context, state) {
          final lostReportId = state.pathParameters['id']!;

          return CreateSightingScreen(lostReportId: lostReportId);
        },
      ),
      GoRoute(
        path: '/sightings/:id',
        builder: (context, state) {
          final sightingId = state.pathParameters['id']!;

          return SightingDetailsScreen(sightingId: sightingId);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
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