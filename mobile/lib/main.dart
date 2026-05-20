import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/api/api_client.dart';
import 'core/navigation/app_router.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage);

  final authRepository = AuthRepository(
    apiClient: apiClient,
    tokenStorage: tokenStorage,
  );

  final authCubit = AuthCubit(authRepository);
  final appRouter = createAppRouter(authCubit);

  runApp(
    PetDadApp(
      authCubit: authCubit,
      appRouter: appRouter,
    ),
  );
}

/// Кореневий віджет застосунку.
class PetDadApp extends StatelessWidget {
  final AuthCubit authCubit;
  final RouterConfig<Object> appRouter;

  const PetDadApp({
    super.key,
    required this.authCubit,
    required this.appRouter,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: MaterialApp.router(
        title: 'PetDad',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: appRouter,
      ),
    );
  }
}