import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/sightings_cubit.dart';
import '../cubit/sightings_state.dart';

/// Екран деталей одного свідчення.
class SightingDetailsScreen extends StatefulWidget {
  final String sightingId;

  const SightingDetailsScreen({
    super.key,
    required this.sightingId,
  });

  @override
  State<SightingDetailsScreen> createState() => _SightingDetailsScreenState();
}

class _SightingDetailsScreenState extends State<SightingDetailsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SightingsCubit>().loadSightingById(widget.sightingId);
    });
  }

  String _confidenceLabel(String confidence) {
    switch (confidence) {
      case 'high':
        return 'Висока';
      case 'medium':
        return 'Середня';
      case 'low':
        return 'Низька';
      default:
        return confidence;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SightingsCubit, SightingsState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );

          context.read<SightingsCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        final sighting = state.selectedSighting;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Деталі свідчення'),
          ),
          body: Builder(
            builder: (context) {
              if (state.isLoading && sighting == null) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (sighting == null) {
                return const Center(
                  child: Text('Свідчення не знайдено'),
                );
              }

              final photoUrl = sighting.pet?.fullMainPhotoUrl;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (photoUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 220,
                        child: Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              child: const Center(
                                child: Icon(Icons.pets, size: 72),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    sighting.pet == null
                        ? 'Свідчення'
                        : 'Свідчення щодо ${sighting.pet!.name}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Chip(
                    label: Text(
                      'Впевненість: ${_confidenceLabel(sighting.confidenceLevel)}',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(label: 'Опис', value: sighting.description),
                  _InfoRow(label: 'Час', value: sighting.seenAt),
                  _InfoRow(
                    label: 'Координати',
                    value:
                        '${sighting.location.latitude}, ${sighting.location.longitude}',
                  ),
                  _InfoRow(
                    label: 'Статус',
                    value: sighting.status,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// Рядок даних свідчення.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}