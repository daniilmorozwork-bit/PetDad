import 'package:flutter/material.dart';

import '../../data/models/lost_report_model.dart';

/// Картка SOS у списку.
class LostReportCard extends StatelessWidget {
  final LostReportModel report;
  final VoidCallback onTap;

  const LostReportCard({
    super.key,
    required this.report,
    required this.onTap,
  });

  String _speciesLabel(String species) {
    switch (species) {
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

  @override
  Widget build(BuildContext context) {
    final photoUrl = report.pet.fullMainPhotoUrl;

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
                  width: 76,
                  height: 76,
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
                      'Зникла тварина: ${report.pet.name}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_speciesLabel(report.pet.species)} • ${report.pet.color}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      report.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: const Text('SOS активне'),
                      backgroundColor: Colors.red.shade100,
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