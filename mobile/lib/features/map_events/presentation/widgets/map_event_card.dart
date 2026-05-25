import 'package:flutter/material.dart';

import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../data/models/map_event_model.dart';

/// Картка події у списку під картою.
/// Натискання на картку фокусує подію на карті,
/// а окрема кнопка відкриває її деталі.
class MapEventCard extends StatelessWidget {
  final MapEventModel event;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onOpenDetails;

  const MapEventCard({
    super.key,
    required this.event,
    required this.isSelected,
    required this.onTap,
    required this.onOpenDetails,
  });

  IconData get _icon {
    switch (event.type) {
      case 'lost_pet':
        return Icons.campaign_outlined;
      case 'sighting':
        return Icons.visibility_outlined;
      case 'found_pet':
        return Icons.pets_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }

  Color _iconBackgroundColor(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    switch (event.type) {
      case 'lost_pet':
        return colors.errorContainer;
      case 'sighting':
        return colors.tertiaryContainer;
      case 'found_pet':
        return colors.primaryContainer;
      default:
        return colors.surfaceContainerHighest;
    }
  }

  Color _iconForegroundColor(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    switch (event.type) {
      case 'lost_pet':
        return colors.onErrorContainer;
      case 'sighting':
        return colors.onTertiaryContainer;
      case 'found_pet':
        return colors.onPrimaryContainer;
      default:
        return colors.onSurfaceVariant;
    }
  }

  String get _locationLabel {
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final details = event.distanceMeters == null
        ? AppFormatters.dateTimeFromIso(event.createdAt)
        : '${AppFormatters.distance(event.distanceMeters!)} від вас';

    return Card(
      color: isSelected
          ? colors.primaryContainer.withOpacity(0.42)
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _iconBackgroundColor(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _icon,
                  color: _iconForegroundColor(context),
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MapEventTypeBadge(
                      type: event.type,
                    ),
                    const SizedBox(height: 7),

                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _locationLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        Icon(
                          event.distanceMeters == null
                              ? Icons.schedule_outlined
                              : Icons.near_me_outlined,
                          size: 15,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            details,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              IconButton(
                onPressed: onOpenDetails,
                icon: const Icon(Icons.open_in_new),
                tooltip: 'Відкрити деталі',
              ),
            ],
          ),
        ),
      ),
    );
  }
}