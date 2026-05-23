import 'package:flutter/material.dart';

import '../../data/models/notification_model.dart';

/// Картка повідомлення у списку.
class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  IconData get _icon {
    switch (notification.type) {
      case 'lost_pet_created':
      case 'lost_pet_nearby':
        return Icons.campaign_outlined;
      case 'new_sighting':
        return Icons.visibility_outlined;
      case 'qr_scanned':
        return Icons.qr_code_scanner_outlined;
      case 'report_status_changed':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _iconBackgroundColor(BuildContext context) {
    switch (notification.type) {
      case 'lost_pet_created':
      case 'lost_pet_nearby':
        return Colors.red.shade100;
      case 'new_sighting':
        return Colors.orange.shade100;
      case 'qr_scanned':
        return Colors.blue.shade100;
      case 'report_status_changed':
        return Colors.green.shade100;
      default:
        return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value)?.toLocal();

    if (date == null) {
      return value;
    }

    String twoDigits(int number) {
      return number.toString().padLeft(2, '0');
    }

    return '${twoDigits(date.day)}.${twoDigits(date.month)}.${date.year} '
        '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: notification.isUnread
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.30)
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: _iconBackgroundColor(context),
                child: Icon(_icon),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (notification.isUnread)
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    Text(
                      notification.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Chip(
                          label: Text(notification.typeLabel),
                          visualDensity: VisualDensity.compact,
                        ),
                        Text(
                          _formatDate(notification.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
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