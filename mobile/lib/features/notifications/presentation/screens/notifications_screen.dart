import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/notification_model.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';
import '../widgets/notification_card.dart';

/// Екран повідомлень поточного користувача.
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
              SnackBar(content: Text(state.errorMessage!)),
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

        return Scaffold(
          appBar: AppBar(
            title: const Text('Повідомлення'),
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
          ),
          body: RefreshIndicator(
            onRefresh: () =>
                context.read<NotificationsCubit>().loadNotifications(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.unreadCount == 0
                                ? 'Нових повідомлень немає'
                                : 'Непрочитаних повідомлень: ${state.unreadCount}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                FilterChip(
                  label: const Text('Лише непрочитані'),
                  selected: _showUnreadOnly,
                  onSelected: (selected) {
                    setState(() {
                      _showUnreadOnly = selected;
                    });
                  },
                ),
                const SizedBox(height: 12),

                if (state.isLoading && state.notifications.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (shownNotifications.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 70),
                    child: Column(
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 72,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showUnreadOnly
                              ? 'Непрочитаних повідомлень немає'
                              : 'Повідомлень поки немає',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Повідомлення зʼявляться після створення SOS, нового свідчення або сканування QR-коду.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...shownNotifications.map(
                    (notification) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: NotificationCard(
                        notification: notification,
                        onTap: () => _openNotification(notification),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}