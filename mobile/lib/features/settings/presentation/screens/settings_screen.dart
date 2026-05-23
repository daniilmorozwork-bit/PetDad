import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/app_section_scaffold.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../data/models/app_settings_model.dart';
import '../cubit/settings_cubit.dart';

/// Екран локальних налаштувань застосунку.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _themeLabel(AppThemePreference preference) {
    switch (preference) {
      case AppThemePreference.system:
        return 'Як у системі';
      case AppThemePreference.light:
        return 'Світла';
      case AppThemePreference.dark:
        return 'Темна';
    }
  }

  String _radiusLabel(int radius) {
    if (radius >= 1000) {
      final kilometers = radius / 1000;

      if (kilometers == kilometers.roundToDouble()) {
        return '${kilometers.round()} км';
      }

      return '$kilometers км';
    }

    return '$radius м';
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;

    String userName = 'Користувач';
    String email = '';

    if (authState is AuthAuthenticated) {
      userName = authState.user.fullName;
      email = authState.user.email;
    }

    return BlocBuilder<SettingsCubit, AppSettingsModel>(
      builder: (context, settings) {
        return AppSectionScaffold(
          title: 'Налаштування',
          currentRoute: '/settings',
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Обліковий запис',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),

              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
                  title: Text(userName),
                  subtitle: Text(email),
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Інтерфейс',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<AppThemePreference>(
                    initialValue: settings.themePreference,
                    decoration: const InputDecoration(
                      labelText: 'Тема застосунку',
                      prefixIcon: Icon(Icons.palette_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: AppThemePreference.values.map((preference) {
                      return DropdownMenuItem(
                        value: preference,
                        child: Text(_themeLabel(preference)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      context.read<SettingsCubit>().changeTheme(value);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Карта та геолокація',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),

              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      value: settings.useCurrentLocation,
                      secondary: const Icon(Icons.my_location),
                      title: const Text('Використовувати мою позицію'),
                      subtitle: const Text(
                        'Автоматично визначати поточне місцезнаходження для карти та форм подій',
                      ),
                      onChanged: (value) {
                        context
                            .read<SettingsCubit>()
                            .changeUseCurrentLocation(value);
                      },
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: DropdownButtonFormField<int>(
                        initialValue: settings.defaultSearchRadiusMeters,
                        decoration: const InputDecoration(
                          labelText: 'Радіус пошуку подій поруч',
                          prefixIcon: Icon(Icons.radar_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 1000,
                            child: Text('1 км'),
                          ),
                          DropdownMenuItem(
                            value: 3000,
                            child: Text('3 км'),
                          ),
                          DropdownMenuItem(
                            value: 5000,
                            child: Text('5 км'),
                          ),
                          DropdownMenuItem(
                            value: 10000,
                            child: Text('10 км'),
                          ),
                          DropdownMenuItem(
                            value: 20000,
                            child: Text('20 км'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          context
                              .read<SettingsCubit>()
                              .changeDefaultSearchRadius(value);

                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Радіус пошуку змінено: ${_radiusLabel(value)}',
                                ),
                              ),
                            );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Повідомлення',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),

              const Card(
                child: ListTile(
                  leading: Icon(Icons.notifications_outlined),
                  title: Text('Внутрішні повідомлення активні'),
                  subtitle: Text(
                    'Push-повідомлення через Firebase будуть підключені в наступній версії.',
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Про застосунок',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),

              const Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.pets_outlined),
                      title: Text('PetDad'),
                      subtitle: Text('MVP для пошуку зниклих тварин'),
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('Версія'),
                      subtitle: Text('0.1.0 MVP'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}