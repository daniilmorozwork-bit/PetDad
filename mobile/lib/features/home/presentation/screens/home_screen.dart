import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_section_card.dart';
import '../../../../shared/widgets/app_section_scaffold.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../current_location/data/models/current_location_model.dart';
import '../../../current_location/presentation/cubit/current_location_cubit.dart';
import '../../../current_location/presentation/cubit/current_location_state.dart';
import '../../../map_events/data/models/map_event_model.dart';
import '../../../map_events/presentation/cubit/map_events_cubit.dart';
import '../../../map_events/presentation/cubit/map_events_state.dart';
import '../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../../../notifications/presentation/cubit/notifications_state.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';

/// Головний dashboard застосунку.
/// Показує події поруч, швидкі дії та короткий огляд стану системи.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Резервна позиція, якщо геолокація вимкнена або недоступна.
  static const LatLng _fallbackCenter = LatLng(50.4501, 30.5234);

  final MapController _mapController = MapController();

  LatLng _mapCenter = _fallbackCenter;
  bool _usingDeviceLocation = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDashboard();
    });
  }

  /// Оновлює позицію, події поруч і внутрішні повідомлення.
  Future<void> _refreshDashboard() async {
    final settings = context.read<SettingsCubit>().state;
    final locationCubit = context.read<CurrentLocationCubit>();

    CurrentLocationModel? location;

    if (settings.useCurrentLocation) {
      location = await locationCubit.loadCurrentLocation();
    } else {
      locationCubit.clearLocation();
    }

    if (!mounted) {
      return;
    }

    final center = location == null
        ? _fallbackCenter
        : LatLng(
            location.latitude,
            location.longitude,
          );

    setState(() {
      _mapCenter = center;
      _usingDeviceLocation = location != null;
    });

    _mapController.move(center, 13);

    await Future.wait([
      context.read<MapEventsCubit>().loadNearbyEvents(
            latitude: center.latitude,
            longitude: center.longitude,
            radiusMeters: settings.defaultSearchRadiusMeters,
          ),
      context.read<NotificationsCubit>().loadNotifications(),
    ]);
  }

  /// Відкриває сутність, пов’язану з подією карти.
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

  /// Створює маркер події для компактної карти.
  Marker _buildEventMarker(MapEventModel event) {
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
      width: 46,
      height: 46,
      child: GestureDetector(
        onTap: () {
          _openEvent(event);
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(0.24),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 7,
                offset: const Offset(0, 2),
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

  /// Створює маркер поточної позиції користувача.
  Marker _buildCurrentLocationMarker(CurrentLocationModel location) {
    return Marker(
      point: LatLng(
        location.latitude,
        location.longitude,
      ),
      width: 46,
      height: 46,
      child: Tooltip(
        message: 'Ваше місцезнаходження',
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.blue.withOpacity(0.24),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 7,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.my_location,
            color: Colors.blue.shade700,
            size: 26,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final locationState = context.watch<CurrentLocationCubit>().state;
    final settings = context.watch<SettingsCubit>().state;

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
                SnackBar(
                  content: Text(state.errorMessage!),
                ),
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
                SnackBar(
                  content: Text(state.errorMessage!),
                ),
              );

            context.read<NotificationsCubit>().clearError();
          },
        ),
      ],
      child: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, notificationsState) {
          return AppSectionScaffold(
            title: 'Головна',
            currentRoute: '/home',
            actions: [
              _NotificationActionButton(
                unreadCount: notificationsState.unreadCount,
                onPressed: () {
                  context.push('/notifications');
                },
              ),
            ],
            body: RefreshIndicator(
              onRefresh: _refreshDashboard,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _WelcomeCard(
                    userName: userName,
                    unreadCount: notificationsState.unreadCount,
                    onOpenNotifications: () {
                      context.push('/notifications');
                    },
                  ),

                  const SizedBox(height: 12),

                  _LocationStatusCard(
                    settingsUseLocation: settings.useCurrentLocation,
                    usingDeviceLocation: _usingDeviceLocation,
                    locationState: locationState,
                    searchRadiusMeters:
                        settings.defaultSearchRadiusMeters,
                    onRetry: _refreshDashboard,
                  ),

                  const SizedBox(height: 12),

                  BlocBuilder<MapEventsCubit, MapEventsState>(
                    builder: (context, mapState) {
                      final sosCount = mapState.events
                          .where((event) => event.type == 'lost_pet')
                          .length;

                      final sightingsCount = mapState.events
                          .where((event) => event.type == 'sighting')
                          .length;

                      final markers = <Marker>[
                        ...mapState.events.map(_buildEventMarker),
                        if (locationState.location != null)
                          _buildCurrentLocationMarker(
                            locationState.location!,
                          ),
                      ];

                      return AppSectionCard(
                        title: 'Події поруч',
                        icon: Icons.map_outlined,
                        trailing: TextButton(
                          onPressed: () {
                            context.push('/map');
                          },
                          child: const Text('Відкрити'),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _EventCounterChip(
                                  icon: Icons.campaign_outlined,
                                  label: 'SOS',
                                  count: sosCount,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .errorContainer,
                                  foregroundColor: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                ),
                                _EventCounterChip(
                                  icon: Icons.visibility_outlined,
                                  label: 'Свідчення',
                                  count: sightingsCount,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .tertiaryContainer,
                                  foregroundColor: Theme.of(context)
                                      .colorScheme
                                      .onTertiaryContainer,
                                ),
                                _EventCounterChip(
                                  icon: Icons.location_on_outlined,
                                  label: 'Усього',
                                  count: mapState.events.length,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  foregroundColor: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                height: 250,
                                child: Stack(
                                  children: [
                                    FlutterMap(
                                      mapController: _mapController,
                                      options: MapOptions(
                                        initialCenter: _mapCenter,
                                        initialZoom: 13,
                                      ),
                                      children: [
                                        TileLayer(
                                          urlTemplate:
                                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                          userAgentPackageName:
                                              'com.petdad.app',
                                        ),
                                        MarkerLayer(
                                          markers: markers,
                                        ),
                                      ],
                                    ),

                                    if (mapState.isLoading ||
                                        locationState.isLoading)
                                      Positioned.fill(
                                        child: Container(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .scrim
                                              .withOpacity(0.10),
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            _MapLegend(
                              showCurrentLocation:
                                  locationState.location != null,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Швидкі дії',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 10),

                  _QuickActionsGrid(
                    unreadCount: notificationsState.unreadCount,
                    onOpenPets: () {
                      context.push('/pets');
                    },
                    onOpenSos: () {
                      context.push('/lost-reports');
                    },
                    onOpenMap: () {
                      context.push('/map');
                    },
                    onOpenNotifications: () {
                      context.push('/notifications');
                    },
                  ),

                  const SizedBox(height: 20),

                  BlocBuilder<MapEventsCubit, MapEventsState>(
                    builder: (context, mapState) {
                      final nearbyEvents = mapState.events.take(3).toList();

                      return AppSectionCard(
                        title: 'Найближчі події',
                        icon: Icons.near_me_outlined,
                        trailing: mapState.events.length > 3
                            ? TextButton(
                                onPressed: () {
                                  context.push('/map');
                                },
                                child: const Text('Усі'),
                              )
                            : null,
                        child: Builder(
                          builder: (context) {
                            if (mapState.isLoading &&
                                mapState.events.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            if (nearbyEvents.isEmpty) {
                              return const _NoNearbyEvents();
                            }

                            return Column(
                              children: nearbyEvents.map((event) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _DashboardEventTile(
                                    event: event,
                                    onTap: () {
                                      _openEvent(event);
                                    },
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Кнопка повідомлень у верхній панелі з лічильником.
class _NotificationActionButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onPressed;

  const _NotificationActionButton({
    required this.unreadCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Повідомлення',
        ),
        if (unreadCount > 0)
          Positioned(
            right: 4,
            top: 5,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onError,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Верхній блок головної сторінки.
class _WelcomeCard extends StatelessWidget {
  final String userName;
  final int unreadCount;
  final VoidCallback onOpenNotifications;

  const _WelcomeCard({
    required this.userName,
    required this.unreadCount,
    required this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 27,
              backgroundColor: colors.primary,
              child: Icon(
                Icons.pets,
                color: colors.onPrimary,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Вітаємо, $userName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    unreadCount == 0
                        ? 'Переглядайте події поруч та керуйте профілями тварин.'
                        : 'У вас є нові повідомлення: $unreadCount.',
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  if (unreadCount > 0) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: onOpenNotifications,
                      style: TextButton.styleFrom(
                        foregroundColor: colors.onPrimaryContainer,
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: const Text('Переглянути повідомлення'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Стан геолокації на dashboard.
class _LocationStatusCard extends StatelessWidget {
  final bool settingsUseLocation;
  final bool usingDeviceLocation;
  final CurrentLocationState locationState;
  final int searchRadiusMeters;
  final VoidCallback onRetry;

  const _LocationStatusCard({
    required this.settingsUseLocation,
    required this.usingDeviceLocation,
    required this.locationState,
    required this.searchRadiusMeters,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Color backgroundColor;
    Color foregroundColor;
    IconData icon;
    String message;
    bool showRetry = false;

    if (!settingsUseLocation) {
      backgroundColor = colors.surfaceContainerHighest;
      foregroundColor = colors.onSurfaceVariant;
      icon = Icons.location_disabled_outlined;
      message =
          'Геолокацію вимкнено. Події показуються для тестової області.';
    } else if (locationState.status == CurrentLocationStatus.error) {
      backgroundColor = colors.errorContainer;
      foregroundColor = colors.onErrorContainer;
      icon = Icons.location_off_outlined;
      message =
          '${locationState.errorMessage ?? 'Не вдалося визначити позицію.'} '
          'Показується тестова область.';
      showRetry = true;
    } else if (locationState.isLoading) {
      backgroundColor = colors.secondaryContainer;
      foregroundColor = colors.onSecondaryContainer;
      icon = Icons.my_location;
      message = 'Визначення вашого місцезнаходження...';
    } else if (usingDeviceLocation) {
      backgroundColor = colors.secondaryContainer;
      foregroundColor = colors.onSecondaryContainer;
      icon = Icons.my_location;
      message =
          'Події показуються в радіусі '
          '${AppFormatters.distance(searchRadiusMeters)} від вашої позиції.';
    } else {
      backgroundColor = colors.surfaceContainerHighest;
      foregroundColor = colors.onSurfaceVariant;
      icon = Icons.location_on_outlined;
      message = 'Для пошуку подій використовується тестова область.';
    }

    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: foregroundColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: foregroundColor,
                ),
              ),
            ),
            if (showRetry)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: foregroundColor,
                ),
                child: const Text('Повторити'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Лічильник типів подій над картою.
class _EventCounterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final Color foregroundColor;

  const _EventCounterChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 17,
            color: foregroundColor,
          ),
          const SizedBox(width: 5),
          Text(
            '$label: $count',
            style: TextStyle(
              color: foregroundColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Легенда компактної карти.
class _MapLegend extends StatelessWidget {
  final bool showCurrentLocation;

  const _MapLegend({
    required this.showCurrentLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [
        const _LegendItem(
          color: Colors.red,
          label: 'SOS',
        ),
        const _LegendItem(
          color: Colors.orange,
          label: 'Свідчення',
        ),
        if (showCurrentLocation)
          const _LegendItem(
            color: Colors.blue,
            label: 'Ваша позиція',
          ),
      ],
    );
  }
}

/// Один пункт легенди карти.
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Сітка швидких дій dashboard.
class _QuickActionsGrid extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onOpenPets;
  final VoidCallback onOpenSos;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenNotifications;

  const _QuickActionsGrid({
    required this.unreadCount,
    required this.onOpenPets,
    required this.onOpenSos,
    required this.onOpenMap,
    required this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 4 : 2;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: columns == 4 ? 1.45 : 1.34,
          children: [
            _QuickActionCard(
              icon: Icons.pets_outlined,
              title: 'Мої тварини',
              description: 'Профілі та QR-коди',
              onTap: onOpenPets,
            ),
            _QuickActionCard(
              icon: Icons.campaign_outlined,
              title: 'SOS-пошук',
              description: 'Активні оголошення',
              onTap: onOpenSos,
            ),
            _QuickActionCard(
              icon: Icons.map_outlined,
              title: 'Карта',
              description: 'Події поблизу',
              onTap: onOpenMap,
            ),
            _QuickActionCard(
              icon: Icons.notifications_outlined,
              title: 'Повідомлення',
              description: unreadCount == 0
                  ? 'Нових немає'
                  : 'Нових: $unreadCount',
              onTap: onOpenNotifications,
              highlighted: unreadCount > 0,
            ),
          ],
        );
      },
    );
  }
}

/// Картка швидкої дії.
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool highlighted;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      color: highlighted ? colors.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: highlighted
                      ? colors.primary
                      : colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: highlighted
                      ? colors.onPrimary
                      : colors.onSecondaryContainer,
                ),
              ),

              const Spacer(),

              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: highlighted
                      ? colors.onPrimaryContainer
                      : null,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: highlighted
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Компактна подія у блоці dashboard.
class _DashboardEventTile extends StatelessWidget {
  final MapEventModel event;
  final VoidCallback onTap;

  const _DashboardEventTile({
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MapEventTypeBadge(
                      type: event.type,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.distanceMeters == null
                          ? AppFormatters.dateTimeFromIso(event.createdAt)
                          : '${AppFormatters.distance(event.distanceMeters!)} від вас',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Порожній стан найближчих подій.
class _NoNearbyEvents extends StatelessWidget {
  const _NoNearbyEvents();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      child: Column(
        children: [
          Icon(
            Icons.location_searching_outlined,
            size: 42,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          const Text(
            'Подій поруч немає',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Активні SOS і свідчення у вибраному радіусі '
            'з’являться у цьому блоці.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}