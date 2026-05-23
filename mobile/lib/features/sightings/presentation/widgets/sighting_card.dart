import 'package:flutter/material.dart';

import '../../data/models/sighting_model.dart';
import '../../../../core/utils/app_formatters.dart';

/// Картка свідчення у списку деталей SOS.
class SightingCard extends StatelessWidget {
  final SightingModel sighting;
  final VoidCallback onTap;

  const SightingCard({
    super.key,
    required this.sighting,
    required this.onTap,
  });

  String get _confidenceLabel {
    switch (sighting.confidenceLevel) {
      case 'high':
        return 'Висока впевненість';
      case 'medium':
        return 'Середня впевненість';
      case 'low':
        return 'Низька впевненість';
      default:
        return sighting.confidenceLevel;
    }
  }

  Color _confidenceColor() {
    switch (sighting.confidenceLevel) {
      case 'high':
        return Colors.green.shade100;
      case 'medium':
        return Colors.orange.shade100;
      case 'low':
        return Colors.grey.shade200;
      default:
        return Colors.blueGrey.shade100;
    }
  }

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
                    Chip(
                      label: Text(_confidenceLabel),
                      backgroundColor: _confidenceColor(),
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