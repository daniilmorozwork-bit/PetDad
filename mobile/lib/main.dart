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

  final authCubit = AuthCubit(authRepository);
  final petsCubit = PetsCubit(petsRepository);
  final qrCubit = QrCubit(qrRepository);

 
  final appRouter = createAppRouter(authCubit);

  runApp(
    PetDadApp(
      authCubit: authCubit,
      petsCubit: petsCubit,
      qrCubit: qrCubit,
      appRouter: appRouter,
    ),
  );
}

/// Кореневий віджет застосунку.
class PetDadApp extends StatelessWidget {
  final AuthCubit authCubit;
  final PetsCubit petsCubit;
  final QrCubit qrCubit;
  final RouterConfig<Object> appRouter;

  const PetDadApp({
    super.key,
    required this.authCubit,
    required this.petsCubit,
    required this.qrCubit,
    required this.appRouter,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<PetsCubit>.value(value: petsCubit),
        BlocProvider<QrCubit>.value(value: qrCubit),
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