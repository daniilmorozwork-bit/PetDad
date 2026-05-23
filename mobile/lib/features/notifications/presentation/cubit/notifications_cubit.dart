import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/notifications_repository.dart';
import 'notifications_state.dart';

/// Cubit для внутрішніх повідомлень.
class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationsRepository _repository;

  NotificationsCubit(this._repository)
      : super(NotificationsState.initial());

  /// Завантажує повідомлення поточного користувача.
  Future<void> loadNotifications() async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
      ),
    );

    try {
      final notifications = await _repository.getMyNotifications();

      emit(
        state.copyWith(
          isLoading: false,
          notifications: notifications,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  /// Позначає одне повідомлення як прочитане.
  Future<void> markAsRead(String notificationId) async {
    try {
      final updatedNotification =
          await _repository.markAsRead(notificationId);

      final updatedList = state.notifications.map((notification) {
        if (notification.id == updatedNotification.id) {
          return updatedNotification;
        }

        return notification;
      }).toList();

      emit(
        state.copyWith(
          notifications: updatedList,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  /// Очищає повідомлення про помилку.
  void clearError() {
    emit(
      state.copyWith(
        clearError: true,
      ),
    );
  }
}