import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../data/models/pet_model.dart';

/// Картка тварини у списку.
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

  String get _statusLabel {
    switch (pet.status) {
      case 'owned':
        return 'Вдома';
      case 'lost':
        return 'Зникла';
      case 'found':
        return 'Знайдена';
      case 'archived':
        return 'Архів';
      default:
        return pet.status;
    }
  }

  Color _statusColor(BuildContext context) {
    switch (pet.status) {
      case 'lost':
        return Colors.red.shade100;
      case 'owned':
        return Colors.green.shade100;
      case 'found':
        return Colors.blue.shade100;
      default:
        return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = AppConfig.buildFileUrl(pet.mainPhotoUrl);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: photoUrl == null
                      ? Container(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: const Icon(Icons.pets, size: 32),
                        )
                      : Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              child: const Icon(Icons.pets, size: 32),
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_speciesLabel}${pet.breed == null ? '' : ' • ${pet.breed}'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(_statusLabel),
                      backgroundColor: _statusColor(context),
                      visualDensity: VisualDensity.compact,
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