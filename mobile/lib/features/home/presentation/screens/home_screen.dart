import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';

/// Тимчасовий головний екран.
/// Пізніше тут будуть швидкі дії: SOS, мої тварини, карта, QR.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

 Future<void> _logout(BuildContext context) async {
  await context.read<AuthCubit>().logout();
}

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthCubit>().state;

    String userName = 'Користувач';

    if (state is AuthAuthenticated) {
      userName = state.user.fullName;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Головна'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Вийти',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Вітаємо, $userName',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'MVP backend підключено',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Наступним кроком додамо розділ “Мої тварини”.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}