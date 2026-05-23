import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../data/models/pet_model.dart';

/// Картка профілю тварини у списку користувача.
class PetCard extends StatelessWidget {
  final PetModel pet;
  final VoidCallback onTap;

  const PetCard({
    super.key,
    required this.pet,
    required this.onTap,
  });

  String get _speciesLabel {
    switch (pet.species) {
      case 'dog':
        return 'Собака';
      case 'cat':
        return 'Кіт';
      case 'bird':
        return 'Птах';
      case 'rabbit':
        return 'Кролик';
      case 'rodent':
        return 'Гризун';
      default:
        return 'Інше';
    }
  }

  String get _description {
    final parts = <String>[
      _speciesLabel,
      if (pet.breed?.trim().isNotEmpty == true) pet.breed!,
      pet.color,
    ];

    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = AppConfig.buildFileUrl(pet.mainPhotoUrl);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: photoUrl == null
                      ? Container(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: Icon(
                            Icons.pets,
                            size: 38,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              child: Icon(
                                Icons.pets,
                                size: 38,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            );
                          },
                        ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),

                    Text(
                      _description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        PetStatusBadge(
                          status: pet.status,
                        ),
                        if (pet.isPublic)
                          _PublicProfileBadge(),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),
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

/// Позначка наявності публічного QR-профілю.
class _PublicProfileBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Chip(
      avatar: Icon(
        Icons.qr_code,
        size: 16,
        color: colorScheme.onSecondaryContainer,
      ),
      label: const Text('QR'),
      labelStyle: TextStyle(
        color: colorScheme.onSecondaryContainer,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: colorScheme.secondaryContainer,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}