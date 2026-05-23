import 'package:flutter/material.dart';

import '../../data/models/map_event_model.dart';

/// Картка події карти у списку під картою.
class MapEventCard extends StatelessWidget {
  final MapEventModel event;
  final VoidCallback onTap;

  const MapEventCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  Color _chipColor() {
    switch (event.type) {
      case 'lost_pet':
        return Colors.red.shade100;
      case 'sighting':
        return Colors.orange.shade100;
      case 'found_pet':
        return Colors.green.shade100;
      default:
        return Colors.blueGrey.shade100;
    }
  }

  IconData _icon() {
    switch (event.type) {
      case 'lost_pet':
        return Icons.campaign_outlined;
      case 'sighting':
        return Icons.visibility_outlined;
      case 'found_pet':
        return Icons.pets;
      default:
        return Icons.location_on_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final distance = event.distanceMeters == null
        ? null
        : '${event.distanceMeters!.round()} м';

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                child: Icon(_icon()),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (event.description != null &&
                        event.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Chip(
                          label: Text(event.typeLabel),
                          backgroundColor: _chipColor(),
                          visualDensity: VisualDensity.compact,
                        ),
                        if (distance != null)
                          Chip(
                            label: Text(distance),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}