import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/api/api_client.dart';
import 'core/navigation/app_router.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/pets/data/repositories/pets_repository.dart';
import 'features/pets/presentation/cubit/pets_cubit.dart';
import 'features/qr/data/repositories/qr_repository.dart';
import 'features/qr/presentation/cubit/qr_cubit.dart';
import 'features/lost_reports/data/repositories/lost_reports_repository.dart';
import 'features/lost_reports/presentation/cubit/lost_reports_cubit.dart';
import 'features/map_events/data/repositories/map_events_repository.dart';
import 'features/map_events/presentation/cubit/map_events_cubit.dart';
import 'features/sightings/data/repositories/sightings_repository.dart';
import 'features/sightings/presentation/cubit/sightings_cubit.dart';
import 'features/notifications/data/repositories/notifications_repository.dart';
import 'features/notifications/presentation/cubit/notifications_cubit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage);

  final authRepository = AuthRepository(
    apiClient: apiClient,
    tokenStorage: tokenStorage,
  );

  final petsRepository = PetsRepository(apiClient: apiClient);
  final qrRepository = QrRepository(apiClient: apiClient);
  final lostReportsRepository = LostReportsRepository(apiClient: apiClient);
  final mapEventsRepository = MapEventsRepository(apiClient: apiClient);
  final sightingsRepository = SightingsRepository(apiClient: apiClient);
  final notificationsRepository = NotificationsRepository(apiClient: apiClient);

  final authCubit = AuthCubit(authRepository);
  final petsCubit = PetsCubit(petsRepository);
  final qrCubit = QrCubit(qrRepository);
  final lostReportsCubit = LostReportsCubit(lostReportsRepository);
  final mapEventsCubit = MapEventsCubit(mapEventsRepository);
  final sightingsCubit = SightingsCubit(sightingsRepository);
  final notificationsCubit = NotificationsCubit(notificationsRepository);

 
  final appRouter = createAppRouter(authCubit);

  runApp(
    PetDadApp(
      authCubit: authCubit,
      petsCubit: petsCubit,
      qrCubit: qrCubit,
      lostReportsCubit: lostReportsCubit,
      mapEventsCubit: mapEventsCubit,
      sightingsCubit: sightingsCubit,
      notificationsCubit: notificationsCubit,
      appRouter: appRouter,
    ),
  );
}

/// Кореневий віджет застосунку.
class PetDadApp extends StatelessWidget {
  final AuthCubit authCubit;
  final PetsCubit petsCubit;
  final QrCubit qrCubit;
  final LostReportsCubit lostReportsCubit;
  final MapEventsCubit mapEventsCubit;
  final SightingsCubit sightingsCubit;
  final NotificationsCubit notificationsCubit;
  final RouterConfig<Object> appRouter;

  const PetDadApp({
    super.key,
    required this.authCubit,
    required this.petsCubit,
    required this.qrCubit,
    required this.lostReportsCubit,
    required this.mapEventsCubit,
    required this.sightingsCubit,
    required this.notificationsCubit,
    required this.appRouter,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<PetsCubit>.value(value: petsCubit),
        BlocProvider<QrCubit>.value(value: qrCubit),
        BlocProvider<LostReportsCubit>.value(value: lostReportsCubit),
        BlocProvider<MapEventsCubit>.value(value: mapEventsCubit),
        BlocProvider<SightingsCubit>.value(value: sightingsCubit),
        BlocProvider<NotificationsCubit>.value(value: notificationsCubit),
      ],
      child: MaterialApp.router(
        title: 'PetDad',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: appRouter,
      ),
    );
  }
}