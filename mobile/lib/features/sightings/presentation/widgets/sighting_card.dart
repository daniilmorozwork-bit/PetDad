import 'package:flutter/material.dart';

import '../../data/models/sighting_model.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/app_badges.dart';

/// Картка свідчення у списку деталей SOS.
class SightingCard extends StatelessWidget {
  final SightingModel sighting;
  final VoidCallback onTap;

  const SightingCard({
    super.key,
    required this.sighting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                child: Icon(Icons.visibility_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sighting.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Помічено: ${AppFormatters.dateTimeFromIso(sighting.seenAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                   ConfidenceBadge(
                    level: sighting.confidenceLevel,
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