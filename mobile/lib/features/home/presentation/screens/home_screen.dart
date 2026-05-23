import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../shared/widgets/app_section_scaffold.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../map_events/data/models/map_event_model.dart';
import '../../../map_events/presentation/cubit/map_events_cubit.dart';
import '../../../map_events/presentation/cubit/map_events_state.dart';
import '../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../../../notifications/presentation/cubit/notifications_state.dart';

/// Головний екран застосунку.
/// Показує компактну карту, швидкі дії та останні активні події.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _defaultLatitude = 50.4501;
  static const double _defaultLongitude = 30.5234;
  static const int _defaultRadiusMeters = 5000;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshHomeData();
    });
  }

  Future<void> _refreshHomeData() async {
    await Future.wait([
      context.read<MapEventsCubit>().loadNearbyEvents(
            latitude: _defaultLatitude,
            longitude: _defaultLongitude,
            radiusMeters: _defaultRadiusMeters,
          ),
      context.read<NotificationsCubit>().loadNotifications(),
    ]);
  }

  void _openEvent(MapEventModel event) {
    if (event.isLostPetEvent && event.sourceEntityId != null) {
      context.push('/lost-reports/${event.sourceEntityId}');
      return;
    }

    if (event.isSightingEvent && event.sourceEntityId != null) {
      context.push('/sightings/${event.sourceEntityId}');
      return;
    }

    context.push('/map');
  }

  Marker _buildMarker(MapEventModel event) {
    final color = switch (event.type) {
      'lost_pet' => Colors.red,
      'sighting' => Colors.orange,
      'found_pet' => Colors.green,
      _ => Colors.blueGrey,
    };

    final icon = switch (event.type) {
      'lost_pet' => Icons.campaign,
      'sighting' => Icons.visibility,
      'found_pet' => Icons.pets,
      _ => Icons.location_on,
    };

    return Marker(
      point: LatLng(
        event.location.latitude,
        event.location.longitude,
      ),
      width: 42,
      height: 42,
      child: GestureDetector(
        onTap: () => _openEvent(event),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 6,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: color,
            size: 27,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;

    String userName = 'Користувач';

    if (authState is AuthAuthenticated) {
      userName = authState.user.fullName;
    }

    return MultiBlocListener(
      listeners: [
        BlocListener<MapEventsCubit, MapEventsState>(
          listenWhen: (previous, current) {
            return current.errorMessage != null &&
                current.errorMessage != previous.errorMessage;
          },
          listener: (context, state) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );

            context.read<MapEventsCubit>().clearMessages();
          },
        ),
        BlocListener<NotificationsCubit, NotificationsState>(
          listenWhen: (previous, current) {
            return current.errorMessage != null &&
                current.errorMessage != previous.errorMessage;
          },
          listener: (context, state) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );

            context.read<NotificationsCubit>().clearError();
          },
        ),
      ],
      child: AppSectionScaffold(
        title: 'Головна',
        currentRoute: '/home',
        body: RefreshIndicator(
          onRefresh: _refreshHomeData,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Вітаємо, $userName',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'Переглядайте події поруч та керуйте профілями тварин.',
              ),
              const SizedBox(height: 20),

              BlocBuilder<MapEventsCubit, MapEventsState>(
                builder: (context, state) {
                  final markers = state.events.map(_buildMarker).toList();

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Активні події поруч',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  context.push('/map');
                                },
                                child: const Text('Відкрити карту'),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 240,
                          child: Stack(
                            children: [
                              FlutterMap(
                                options: MapOptions(
                                  initialCenter: const LatLng(
                                    _defaultLatitude,
                                    _defaultLongitude,
                                  ),
                                  initialZoom: 13,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.petdad.app',
                                  ),
                                  MarkerLayer(
                                    markers: markers,
                                  ),
                                ],
                              ),
                              Positioned(
                                left: 10,
                                bottom: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.94),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    'Подій: ${state.events.length}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              if (state.isLoading)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black.withOpacity(0.06),
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
              const Text(
                'Швидкі дії',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              BlocBuilder<NotificationsCubit, NotificationsState>(
                builder: (context, notificationsState) {
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.45,
                    children: [
                      _QuickActionCard(
                        icon: Icons.pets_outlined,
                        title: 'Мої тварини',
                        description: 'Профілі та QR',
                        onTap: () => context.push('/pets'),
                      ),
                      _QuickActionCard(
                        icon: Icons.campaign_outlined,
                        title: 'SOS-пошук',
                        description: 'Активні оголошення',
                        onTap: () => context.push('/lost-reports'),
                      ),
                      _QuickActionCard(
                        icon: Icons.map_outlined,
                        title: 'Карта',
                        description: 'Події поруч',
                        onTap: () => context.push('/map'),
                      ),
                      _QuickActionCard(
                        icon: Icons.notifications_outlined,
                        title: 'Повідомлення',
                        description: notificationsState.unreadCount == 0
                            ? 'Нових немає'
                            : 'Нових: ${notificationsState.unreadCount}',
                        onTap: () => context.push('/notifications'),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),
              const Text(
                'Останні події',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),

              BlocBuilder<MapEventsCubit, MapEventsState>(
                builder: (context, state) {
                  if (state.events.isEmpty && !state.isLoading) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Активних подій поруч поки немає.',
                        ),
                      ),
                    );
                  }

                  final recentEvents = state.events.take(3).toList();

                  return Column(
                    children: recentEvents.map((event) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _HomeEventTile(
                          event: event,
                          onTap: () => _openEvent(event),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Картка швидкої дії.
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 29,
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Скорочена картка останньої події.
class _HomeEventTile extends StatelessWidget {
  final MapEventModel event;
  final VoidCallback onTap;

  const _HomeEventTile({
    required this.event,
    required this.onTap,
  });

  IconData get _icon {
    switch (event.type) {
      case 'lost_pet':
        return Icons.campaign_outlined;
      case 'sighting':
        return Icons.visibility_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          _icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          event.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(event.typeLabel),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}