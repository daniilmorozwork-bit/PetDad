import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/map_event_model.dart';
import '../cubit/map_events_cubit.dart';
import '../cubit/map_events_state.dart';
import '../widgets/map_event_card.dart';

/// Екран карти з подіями.
/// Поки що використовує фіксований центр. GPS додамо окремим блоком.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const double _defaultLatitude = 50.4501;
  static const double _defaultLongitude = 30.5234;
  static const int _defaultRadiusMeters = 5000;

  final MapController _mapController = MapController();

  String? _selectedType;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNearbyEvents();
    });
  }

  Future<void> _loadNearbyEvents() async {
    await context.read<MapEventsCubit>().loadNearbyEvents(
          latitude: _defaultLatitude,
          longitude: _defaultLongitude,
          radiusMeters: _defaultRadiusMeters,
          type: _selectedType,
        );
  }

  void _openEvent(MapEventModel event) {
    if (event.isLostPetEvent && event.sourceEntityId != null) {
      context.push('/lost-reports/${event.sourceEntityId}');
      return;
    }

    if (event.isSightingEvent) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Деталі свідчень додамо в наступному модулі',
            ),
          ),
        );
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

  Marker _buildMarker(MapEventModel event) {
    final point = LatLng(
      event.location.latitude,
      event.location.longitude,
    );

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
      point: point,
      width: 48,
      height: 48,
      child: GestureDetector(
        onTap: () {
          context.read<MapEventsCubit>().selectEventById(event.id);

          _showEventBottomSheet(event);
        },
        child: Icon(
          icon,
          color: color,
          size: 42,
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
              Text(event.description ?? 'Опис відсутній'),
              const SizedBox(height: 12),
              Text(
                'Координати: ${event.location.latitude}, ${event.location.longitude}',
              ),
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
        final center = const LatLng(
          _defaultLatitude,
          _defaultLongitude,
        );

        final markers = state.events.map(_buildMarker).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Карта подій'),
            actions: [
              IconButton(
                onPressed: state.isLoading ? null : _loadNearbyEvents,
                icon: const Icon(Icons.refresh),
                tooltip: 'Оновити',
              ),
            ],
          ),
          body: Column(
            children: [
              SizedBox(
                height: 360,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: center,
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

                    if (state.isLoading)
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
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _selectedType,
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
                  ],
                ),
              ),

              Expanded(
                child: Builder(
                  builder: (context) {
                    if (state.events.isEmpty && state.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (state.events.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: _loadNearbyEvents,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: const [
                            SizedBox(height: 40),
                            Icon(Icons.map_outlined, size: 72),
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
                              'Після створення SOS або свідчення події зʼявляться тут.',
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
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
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