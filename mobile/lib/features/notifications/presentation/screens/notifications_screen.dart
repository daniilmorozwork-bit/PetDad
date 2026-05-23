import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_section_scaffold.dart';
import '../../data/models/notification_model.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';
import '../widgets/notification_card.dart';

/// Екран внутрішніх повідомлень поточного користувача.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsCubit>().loadNotifications();
    });
  }

  /// Позначає повідомлення як прочитане та відкриває пов’язаний екран.
  Future<void> _openNotification(NotificationModel notification) async {
    if (notification.isUnread) {
      await context.read<NotificationsCubit>().markAsRead(notification.id);
    }

    if (!mounted) {
      return;
    }

    final entityType = notification.entityType;
    final entityId = notification.entityId;

    if (entityType == 'lost_pet_report' && entityId != null) {
      context.push('/lost-reports/$entityId');
      return;
    }

    if (entityType == 'sighting_report' && entityId != null) {
      context.push('/sightings/$entityId');
      return;
    }

    if (entityType == 'qr_scan_event') {
      final petId = notification.data?['petId'];

      if (petId is String && petId.isNotEmpty) {
        context.push('/pets/$petId');
        return;
      }
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(notification.body),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationsCubit, NotificationsState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
              ),
            );

          context.read<NotificationsCubit>().clearError();
        }
      },
      builder: (context, state) {
        final shownNotifications = _showUnreadOnly
            ? state.notifications
                .where((notification) => notification.isUnread)
                .toList()
            : state.notifications;

        return AppSectionScaffold(
          title: 'Повідомлення',
          currentRoute: '/notifications',
          actions: [
            IconButton(
              onPressed: state.isLoading
                  ? null
                  : () {
                      context
                          .read<NotificationsCubit>()
                          .loadNotifications();
                    },
              icon: const Icon(Icons.refresh),
              tooltip: 'Оновити',
            ),
          ],
          body: RefreshIndicator(
            onRefresh: () =>
                context.read<NotificationsCubit>().loadNotifications(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _NotificationsSummaryCard(
                  totalCount: state.notifications.length,
                  unreadCount: state.unreadCount,
                ),

                const SizedBox(height: 16),

                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: false,
                      icon: Icon(Icons.notifications_outlined),
                      label: Text('Усі'),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      icon: Icon(Icons.mark_email_unread_outlined),
                      label: Text('Непрочитані'),
                    ),
                  ],
                  selected: {_showUnreadOnly},
                  onSelectionChanged: (selected) {
                    setState(() {
                      _showUnreadOnly = selected.first;
                    });
                  },
                ),

                const SizedBox(height: 18),

                if (state.isLoading && state.notifications.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 52),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (shownNotifications.isEmpty)
                  AppEmptyState(
                    icon: _showUnreadOnly
                        ? Icons.mark_email_read_outlined
                        : Icons.notifications_none,
                    title: _showUnreadOnly
                        ? 'Непрочитаних повідомлень немає'
                        : 'Повідомлень поки немає',
                    message: _showUnreadOnly
                        ? 'Усі отримані повідомлення вже прочитані.'
                        : 'Тут з’являтимуться повідомлення про SOS, '
                            'свідчення та сканування QR-коду.',
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _showUnreadOnly
                              ? 'Нові повідомлення'
                              : 'Усі повідомлення',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${shownNotifications.length}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  ...shownNotifications.map(
                    (notification) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: NotificationCard(
                        notification: notification,
                        onTap: () => _openNotification(notification),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Верхній інформаційний блок повідомлень.
class _NotificationsSummaryCard extends StatelessWidget {
  final int totalCount;
  final int unreadCount;

  const _NotificationsSummaryCard({
    required this.totalCount,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final hasUnread = unreadCount > 0;

    final backgroundColor = hasUnread
        ? colors.primaryContainer
        : colors.surfaceContainerHighest;

    final foregroundColor = hasUnread
        ? colors.onPrimaryContainer
        : colors.onSurfaceVariant;

    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              hasUnread
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_none,
              size: 30,
              color: foregroundColor,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasUnread
                        ? 'Є нові повідомлення'
                        : 'Нових повідомлень немає',
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasUnread
                        ? 'Непрочитаних: $unreadCount. Всього: $totalCount.'
                        : 'Всього повідомлень: $totalCount.',
                    style: TextStyle(
                      color: foregroundColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}