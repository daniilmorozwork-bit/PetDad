import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../shared/widgets/app_section_scaffold.dart';
import '../../../current_location/data/models/current_location_model.dart';
import '../../../current_location/presentation/cubit/current_location_cubit.dart';
import '../../../current_location/presentation/cubit/current_location_state.dart';
import '../../data/models/map_event_model.dart';
import '../cubit/map_events_cubit.dart';
import '../cubit/map_events_state.dart';
import '../widgets/map_event_card.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/app_badges.dart';

/// Екран карти з активними подіями.
/// Використовує реальне місцезнаходження користувача.
/// Якщо доступ до геолокації не надано, показує тестову область.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  /// Резервна тестова позиція, якщо користувач не дозволив геолокацію.
  static const LatLng _fallbackCenter = LatLng(50.4501, 30.5234);
  static const int _defaultRadiusMeters = 5000;

  final MapController _mapController = MapController();

  LatLng _searchCenter = _fallbackCenter;
  bool _usingDeviceLocation = false;
  String? _selectedType;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _locateAndLoadEvents();
    });
  }

  /// Отримує позицію користувача, якщо геолокація дозволена в налаштуваннях.
Future<void> _locateAndLoadEvents() async {
  final settings = context.read<SettingsCubit>().state;
  final locationCubit = context.read<CurrentLocationCubit>();

  if (!settings.useCurrentLocation) {
    locationCubit.clearLocation();

    setState(() {
      _searchCenter = _fallbackCenter;
      _usingDeviceLocation = false;
    });

    _mapController.move(_fallbackCenter, 13);

    await _loadNearbyEvents();
    return;
  }

  final location = await locationCubit.loadCurrentLocation();

  if (!mounted) {
    return;
  }

  if (location != null) {
    final center = LatLng(
      location.latitude,
      location.longitude,
    );

    setState(() {
      _searchCenter = center;
      _usingDeviceLocation = true;
    });

    _mapController.move(center, 13);
  } else {
    setState(() {
      _searchCenter = _fallbackCenter;
      _usingDeviceLocation = false;
    });

    _mapController.move(_fallbackCenter, 13);
  }

  await _loadNearbyEvents();
}

  /// Завантажує події у вибраному користувачем радіусі.
Future<void> _loadNearbyEvents() async {
  final settings = context.read<SettingsCubit>().state;

  await context.read<MapEventsCubit>().loadNearbyEvents(
        latitude: _searchCenter.latitude,
        longitude: _searchCenter.longitude,
        radiusMeters: settings.defaultSearchRadiusMeters,
        type: _selectedType,
      );
}

  /// Відкриває повʼязану сутність події.
  void _openEvent(MapEventModel event) {
    if (event.isLostPetEvent && event.sourceEntityId != null) {
      context.push('/lost-reports/${event.sourceEntityId}');
      return;
    }

    if (event.isSightingEvent && event.sourceEntityId != null) {
      context.push('/sightings/${event.sourceEntityId}');
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(event.title)),
      );
  }

  /// Створює маркер події.
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
      width: 52,
      height: 52,
      child: GestureDetector(
        onTap: () {
          _showEventBottomSheet(event);
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
            size: 29,
          ),
        ),
      ),
    );
  }

  /// Створює синій маркер поточної позиції користувача.
  Marker _buildCurrentLocationMarker(
    CurrentLocationModel location,
  ) {
    return Marker(
      point: LatLng(
        location.latitude,
        location.longitude,
      ),
      width: 52,
      height: 52,
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
                blurRadius: 6,
              ),
            ],
          ),
          child: Icon(
            Icons.my_location,
            color: Colors.blue.shade700,
            size: 28,
          ),
        ),
      ),
    );
  }

  void _showEventBottomSheet(MapEventModel event) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              MapEventTypeBadge(
                type: event.type,
              ),
              const SizedBox(height: 10),
              Text(event.description ?? 'Опис відсутній'),
              const SizedBox(height: 12),
              Text(
                'Додано: ${AppFormatters.dateTimeFromIso(event.createdAt)}',
              ),
              if (event.distanceMeters != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Відстань від вас: '
                  '${AppFormatters.distance(event.distanceMeters!)}',
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _openEvent(event);
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Відкрити деталі'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _changeFilter(String? type) {
    setState(() {
      _selectedType = type;
    });

    _loadNearbyEvents();
  }

  @override
  Widget build(BuildContext context) {
    final locationState = context.watch<CurrentLocationCubit>().state;
    final settings = context.watch<SettingsCubit>().state;

    return BlocConsumer<MapEventsCubit, MapEventsState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );

          context.read<MapEventsCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        final markers = <Marker>[
          ...state.events.map(_buildEventMarker),
          if (locationState.location != null)
            _buildCurrentLocationMarker(locationState.location!),
        ];

        return AppSectionScaffold(
          title: 'Карта подій',
          currentRoute: '/map',
          actions: [
            IconButton(
              onPressed: !settings.useCurrentLocation || locationState.isLoading
                  ? null
                  : _locateAndLoadEvents,
              icon: const Icon(Icons.my_location),
              tooltip: settings.useCurrentLocation
                  ? 'Моє місцезнаходження'
                  : 'Геолокація вимкнена у налаштуваннях',
            ),
            IconButton(
              onPressed: state.isLoading ? null : _loadNearbyEvents,
              icon: const Icon(Icons.refresh),
              tooltip: 'Оновити події',
            ),
          ],
          body: Column(
            children: [
              if (!settings.useCurrentLocation)
                _LocationNotice(
                  message:
                      'Геолокацію вимкнено у налаштуваннях. '
                      'Показується тестова область.',
                  onRetry: null,
                  isError: false,
                )
              else if (locationState.status == CurrentLocationStatus.error)
                _LocationNotice(
                  message:
                      '${locationState.errorMessage ?? 'Геолокація недоступна.'} '
                      'Показується тестова область.',
                  onRetry: _locateAndLoadEvents,
                  isError: true,
                )
              else if (_usingDeviceLocation &&
                  locationState.location != null)
                _LocationNotice(
                  message:
                  'Вашу позицію визначено з точністю '
                  '± ${locationState.location!.accuracyMeters} м. '
                  'Показуються події в радіусі '
                  '${AppFormatters.distance(settings.defaultSearchRadiusMeters)}.',
                  onRetry: _locateAndLoadEvents,
                  isError: false,
                ),

              SizedBox(
                height: 340,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _searchCenter,
                        initialZoom: 13,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.petdad.app',
                        ),
                        MarkerLayer(markers: markers),
                      ],
                    ),
                    if (state.isLoading || locationState.isLoading)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.08),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: DropdownButtonFormField<String?>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Тип події',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Усі події'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'lost_pet',
                      child: Text('SOS'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'sighting',
                      child: Text('Свідчення'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'found_pet',
                      child: Text('Знайдені'),
                    ),
                  ],
                  onChanged: state.isLoading ? null : _changeFilter,
                ),
              ),

              Expanded(
                child: Builder(
                  builder: (context) {
                    if (state.events.isEmpty && !state.isLoading) {
                      return RefreshIndicator(
                        onRefresh: _loadNearbyEvents,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: const [
                            SizedBox(height: 32),
                            Icon(Icons.map_outlined, size: 64),
                            SizedBox(height: 16),
                            Text(
                              'Подій поруч немає',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Події відображаються лише в обраному радіусі від вашої позиції.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _loadNearbyEvents,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.events.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final event = state.events[index];

                          return MapEventCard(
                            event: event,
                            onTap: () => _openEvent(event),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Повідомлення про стан геолокації.
class _LocationNotice extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool isError;

  const _LocationNotice({
    required this.message,
    required this.onRetry,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final backgroundColor = isError
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;

    final foregroundColor = isError
        ? colorScheme.onErrorContainer
        : colorScheme.onPrimaryContainer;

    return Container(
      width: double.infinity,
      color: backgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Icon(
            isError
                ? Icons.location_off_outlined
                : Icons.my_location,
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
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: foregroundColor,
              ),
              child: const Text('Оновити'),
            ),
        ],
      ),
    );
  }
}