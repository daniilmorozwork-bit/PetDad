import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_section_scaffold.dart';
import '../../../current_location/data/models/current_location_model.dart';
import '../../../current_location/presentation/cubit/current_location_cubit.dart';
import '../../../current_location/presentation/cubit/current_location_state.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../data/models/map_event_model.dart';
import '../cubit/map_events_cubit.dart';
import '../cubit/map_events_state.dart';
import '../widgets/map_event_card.dart';

/// Екран карти активних подій.
/// Показує події поруч, фільтри та список результатів,
/// пов’язаний із маркерами на карті.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  /// Резервна тестова позиція, якщо геолокація вимкнена
  /// або користувач не надав доступ.
  static const LatLng _fallbackCenter = LatLng(50.4501, 30.5234);

  final MapController _mapController = MapController();

  LatLng _searchCenter = _fallbackCenter;
  bool _usingDeviceLocation = false;
  String? _selectedType;
  String? _selectedEventId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _locateAndLoadEvents();
    });
  }

  /// Визначає поточну позицію, якщо це дозволено налаштуваннями,
  /// і завантажує події поблизу.
  Future<void> _locateAndLoadEvents() async {
    final settings = context.read<SettingsCubit>().state;
    final locationCubit = context.read<CurrentLocationCubit>();

    if (!settings.useCurrentLocation) {
      locationCubit.clearLocation();

      if (!mounted) {
        return;
      }

      setState(() {
        _searchCenter = _fallbackCenter;
        _usingDeviceLocation = false;
        _selectedEventId = null;
      });

      _mapController.move(_fallbackCenter, 13);

      await _loadNearbyEvents();
      return;
    }

    final location = await locationCubit.loadCurrentLocation();

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
      _searchCenter = center;
      _usingDeviceLocation = location != null;
      _selectedEventId = null;
    });

    _mapController.move(center, 13);

    await _loadNearbyEvents();
  }

  /// Завантажує події навколо поточного центру пошуку.
  Future<void> _loadNearbyEvents() async {
    final settings = context.read<SettingsCubit>().state;

    await context.read<MapEventsCubit>().loadNearbyEvents(
          latitude: _searchCenter.latitude,
          longitude: _searchCenter.longitude,
          radiusMeters: settings.defaultSearchRadiusMeters,
          type: _selectedType,
        );
  }

  /// Змінює фільтр типу подій.
  Future<void> _changeFilter(String? type) async {
    if (_selectedType == type) {
      return;
    }

    setState(() {
      _selectedType = type;
      _selectedEventId = null;
    });

    await _loadNearbyEvents();
  }

  /// Фокусує карту на події та відкриває її короткий перегляд.
  void _focusEvent(MapEventModel event) {
    setState(() {
      _selectedEventId = event.id;
    });

    context.read<MapEventsCubit>().selectEventById(event.id);

    _mapController.move(
      LatLng(
        event.location.latitude,
        event.location.longitude,
      ),
      15,
    );

    _showEventBottomSheet(event);
  }

  /// Відкриває сторінку сутності, пов’язаної з подією.
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
        SnackBar(
          content: Text(event.title),
        ),
      );
  }

  Color _eventColor(String type) {
    switch (type) {
      case 'lost_pet':
        return Colors.red;
      case 'sighting':
        return Colors.orange;
      case 'found_pet':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _eventIcon(String type) {
    switch (type) {
      case 'lost_pet':
        return Icons.campaign;
      case 'sighting':
        return Icons.visibility;
      case 'found_pet':
        return Icons.pets;
      default:
        return Icons.location_on;
    }
  }

  String _locationLabel(MapEventModel event) {
    final address = event.location.address?.trim();

    if (address != null && address.isNotEmpty) {
      return address;
    }

    final city = event.location.city?.trim();

    if (city != null && city.isNotEmpty) {
      return city;
    }

    return 'Місце позначено на карті';
  }

  /// Маркер SOS, свідчення або іншої події.
  Marker _buildEventMarker(MapEventModel event) {
    final color = _eventColor(event.type);
    final isSelected = event.id == _selectedEventId;

    return Marker(
      point: LatLng(
        event.location.latitude,
        event.location.longitude,
      ),
      width: isSelected ? 60 : 52,
      height: isSelected ? 60 : 52,
      child: GestureDetector(
        onTap: () {
          _focusEvent(event);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(isSelected ? 0.76 : 0.24),
              width: isSelected ? 3 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isSelected ? 0.24 : 0.18),
                blurRadius: isSelected ? 11 : 7,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            _eventIcon(event.type),
            color: color,
            size: isSelected ? 32 : 29,
          ),
        ),
      ),
    );
  }

  /// Маркер поточної позиції користувача.
  Marker _buildCurrentLocationMarker(CurrentLocationModel location) {
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
              color: Colors.blue.withOpacity(0.32),
              width: 1.7,
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
            size: 28,
          ),
        ),
      ),
    );
  }

  /// Показує коротку інформацію про вибрану подію.
  void _showEventBottomSheet(MapEventModel event) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final colors = Theme.of(sheetContext).colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MapEventTypeBadge(
                  type: event.type,
                ),

                const SizedBox(height: 12),

                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                if (event.description?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 7),
                  Text(
                    event.description!,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                _BottomSheetInfoRow(
                  icon: Icons.location_on_outlined,
                  value: _locationLabel(event),
                ),

                const SizedBox(height: 8),

                _BottomSheetInfoRow(
                  icon: Icons.schedule_outlined,
                  value: AppFormatters.dateTimeFromIso(event.createdAt),
                ),

                if (event.distanceMeters != null) ...[
                  const SizedBox(height: 8),
                  _BottomSheetInfoRow(
                    icon: Icons.near_me_outlined,
                    value:
                        '${AppFormatters.distance(event.distanceMeters!)} від вас',
                  ),
                ],

                const SizedBox(height: 18),

                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _openEvent(event);
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Відкрити деталі'),
                ),
              ],
            ),
          ),
        );
      },
    );
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
              SnackBar(
                content: Text(state.errorMessage!),
              ),
            );

          context.read<MapEventsCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        final sosCount = state.events
            .where((event) => event.type == 'lost_pet')
            .length;

        final sightingsCount = state.events
            .where((event) => event.type == 'sighting')
            .length;

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
              onPressed: !settings.useCurrentLocation ||
                      locationState.isLoading
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
                const _LocationNotice(
                  tone: _NoticeTone.neutral,
                  message:
                      'Геолокацію вимкнено. Показується тестова область.',
                )
              else if (locationState.status == CurrentLocationStatus.error)
                _LocationNotice(
                  tone: _NoticeTone.error,
                  message:
                      '${locationState.errorMessage ?? 'Геолокація недоступна.'} '
                      'Показується тестова область.',
                  onRetry: _locateAndLoadEvents,
                )
              else if (_usingDeviceLocation &&
                  locationState.location != null)
                _LocationNotice(
                  tone: _NoticeTone.info,
                  message:
                      'Події показуються в радіусі '
                      '${AppFormatters.distance(settings.defaultSearchRadiusMeters)} '
                      'від вашої позиції.',
                  onRetry: _locateAndLoadEvents,
                ),

              Expanded(
                flex: 10,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: FlutterMap(
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
                          MarkerLayer(
                            markers: markers,
                          ),
                        ],
                      ),
                    ),

                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: _MapStatisticsOverlay(
                        sosCount: sosCount,
                        sightingsCount: sightingsCount,
                        totalCount: state.events.length,
                      ),
                    ),

                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: _MapLegendCard(
                        showCurrentLocation: locationState.location != null,
                      ),
                    ),

                    if (state.isLoading || locationState.isLoading)
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

              _MapFiltersBar(
                selectedType: _selectedType,
                isLoading: state.isLoading,
                onChanged: _changeFilter,
              ),

              Expanded(
                flex: 9,
                child: _EventsPanel(
                  events: state.events,
                  isLoading: state.isLoading,
                  selectedEventId: _selectedEventId,
                  radiusMeters: settings.defaultSearchRadiusMeters,
                  onRefresh: _loadNearbyEvents,
                  onEventSelected: _focusEvent,
                  onOpenDetails: _openEvent,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _NoticeTone {
  info,
  error,
  neutral,
}

/// Повідомлення про стан геолокації.
class _LocationNotice extends StatelessWidget {
  final _NoticeTone tone;
  final String message;
  final VoidCallback? onRetry;

  const _LocationNotice({
    required this.tone,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final backgroundColor = switch (tone) {
      _NoticeTone.info => colors.secondaryContainer,
      _NoticeTone.error => colors.errorContainer,
      _NoticeTone.neutral => colors.surfaceContainerHighest,
    };

    final foregroundColor = switch (tone) {
      _NoticeTone.info => colors.onSecondaryContainer,
      _NoticeTone.error => colors.onErrorContainer,
      _NoticeTone.neutral => colors.onSurfaceVariant,
    };

    final icon = switch (tone) {
      _NoticeTone.info => Icons.my_location,
      _NoticeTone.error => Icons.location_off_outlined,
      _NoticeTone.neutral => Icons.location_disabled_outlined,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Card(
        margin: EdgeInsets.zero,
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 9, 6, 9),
          child: Row(
            children: [
              Icon(
                icon,
                color: foregroundColor,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: foregroundColor,
                  ),
                ),
              ),
              if (onRetry != null)
                IconButton(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  color: foregroundColor,
                  tooltip: 'Оновити позицію',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Лічильники подій поверх карти.
class _MapStatisticsOverlay extends StatelessWidget {
  final int sosCount;
  final int sightingsCount;
  final int totalCount;

  const _MapStatisticsOverlay({
    required this.sosCount,
    required this.sightingsCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.surface.withOpacity(0.94),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 9,
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MapCounter(
              icon: Icons.campaign_outlined,
              label: 'SOS',
              count: sosCount,
              backgroundColor: colors.errorContainer,
              foregroundColor: colors.onErrorContainer,
            ),
            _MapCounter(
              icon: Icons.visibility_outlined,
              label: 'Свідчення',
              count: sightingsCount,
              backgroundColor: colors.tertiaryContainer,
              foregroundColor: colors.onTertiaryContainer,
            ),
            _MapCounter(
              icon: Icons.location_on_outlined,
              label: 'Усього',
              count: totalCount,
              backgroundColor: colors.surfaceContainerHighest,
              foregroundColor: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Один лічильник подій поверх карти.
class _MapCounter extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color backgroundColor;
  final Color foregroundColor;

  const _MapCounter({
    required this.icon,
    required this.label,
    required this.count,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: foregroundColor,
          ),
          const SizedBox(width: 5),
          Text(
            '$label: $count',
            style: TextStyle(
              color: foregroundColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Легенда маркерів карти.
class _MapLegendCard extends StatelessWidget {
  final bool showCurrentLocation;

  const _MapLegendCard({
    required this.showCurrentLocation,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.surface.withOpacity(0.94),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 9,
        ),
        child: Wrap(
          spacing: 16,
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
        ),
      ),
    );
  }
}

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

/// Горизонтальні фільтри типу подій.
class _MapFiltersBar extends StatelessWidget {
  final String? selectedType;
  final bool isLoading;
  final ValueChanged<String?> onChanged;

  const _MapFiltersBar({
    required this.selectedType,
    required this.isLoading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SizedBox(
        height: 62,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          children: [
            _buildChip(
              value: null,
              label: 'Усі',
              icon: Icons.layers_outlined,
            ),
            const SizedBox(width: 8),
            _buildChip(
              value: 'lost_pet',
              label: 'SOS',
              icon: Icons.campaign_outlined,
            ),
            const SizedBox(width: 8),
            _buildChip(
              value: 'sighting',
              label: 'Свідчення',
              icon: Icons.visibility_outlined,
            ),
            const SizedBox(width: 8),
            _buildChip(
              value: 'found_pet',
              label: 'Знайдені',
              icon: Icons.pets_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required String? value,
    required String label,
    required IconData icon,
  }) {
    return FilterChip(
      avatar: Icon(
        icon,
        size: 18,
      ),
      label: Text(label),
      selected: selectedType == value,
      onSelected: isLoading
          ? null
          : (_) {
              onChanged(value);
            },
    );
  }
}

/// Нижня панель зі списком подій карти.
class _EventsPanel extends StatelessWidget {
  final List<MapEventModel> events;
  final bool isLoading;
  final String? selectedEventId;
  final int radiusMeters;
  final Future<void> Function() onRefresh;
  final ValueChanged<MapEventModel> onEventSelected;
  final ValueChanged<MapEventModel> onOpenDetails;

  const _EventsPanel({
    required this.events,
    required this.isLoading,
    required this.selectedEventId,
    required this.radiusMeters,
    required this.onRefresh,
    required this.onEventSelected,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: colors.outlineVariant,
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Події в радіусі ${AppFormatters.distance(radiusMeters)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${events.length}',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Builder(
              builder: (context) {
                if (isLoading && events.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (events.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: onRefresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      children: [
                        Icon(
                          Icons.location_searching_outlined,
                          size: 46,
                          color: colors.primary,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Подій поруч немає',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Змініть фільтр або оновіть позицію, '
                          'щоб перевірити інші події.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: onRefresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final event = events[index];

                      return MapEventCard(
                        event: event,
                        isSelected: event.id == selectedEventId,
                        onTap: () {
                          onEventSelected(event);
                        },
                        onOpenDetails: () {
                          onOpenDetails(event);
                        },
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
  }
}

/// Рядок даних у нижньому вікні події.
class _BottomSheetInfoRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const _BottomSheetInfoRow({
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}