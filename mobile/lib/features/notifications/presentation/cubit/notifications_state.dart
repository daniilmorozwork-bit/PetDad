import 'package:equatable/equatable.dart';

import '../../data/models/notification_model.dart';

/// Стан модуля повідомлень.
class NotificationsState extends Equatable {
  final bool isLoading;
  final List<NotificationModel> notifications;
  final String? errorMessage;

  const NotificationsState({
    required this.isLoading,
    required this.notifications,
    required this.errorMessage,
  });

  factory NotificationsState.initial() {
    return const NotificationsState(
      isLoading: false,
      notifications: [],
      errorMessage: null,
    );
  }

  /// Кількість непрочитаних повідомлень.
  int get unreadCount {
    return notifications.where((item) => item.isUnread).length;
  }

  NotificationsState copyWith({
    bool? isLoading,
    List<NotificationModel>? notifications,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        notifications,
        errorMessage,
      ];
}