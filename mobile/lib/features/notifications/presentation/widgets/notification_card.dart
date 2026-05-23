import 'package:flutter/material.dart';

import '../../../../core/utils/app_formatters.dart';
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
    final colors = Theme.of(context).colorScheme;

    switch (notification.type) {
      case 'lost_pet_created':
      case 'lost_pet_nearby':
        return colors.errorContainer;
      case 'new_sighting':
        return colors.tertiaryContainer;
      case 'qr_scanned':
        return colors.secondaryContainer;
      case 'report_status_changed':
        return colors.primaryContainer;
      default:
        return colors.surfaceContainerHighest;
    }
  }

  Color _iconForegroundColor(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    switch (notification.type) {
      case 'lost_pet_created':
      case 'lost_pet_nearby':
        return colors.onErrorContainer;
      case 'new_sighting':
        return colors.onTertiaryContainer;
      case 'qr_scanned':
        return colors.onSecondaryContainer;
      case 'report_status_changed':
        return colors.onPrimaryContainer;
      default:
        return colors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      color: notification.isUnread
          ? colors.primaryContainer.withOpacity(0.34)
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
                child: Icon(
                  _icon,
                  color: _iconForegroundColor(context),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        if (notification.isUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(top: 5),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 5),

                    Text(
                      notification.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            notification.typeLabel,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppFormatters.dateTimeFromIso(
                              notification.createdAt,
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}