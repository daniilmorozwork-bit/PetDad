import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/lost_reports_repository.dart';
import 'lost_reports_state.dart';

/// Cubit для SOS-оголошень.
class LostReportsCubit extends Cubit<LostReportsState> {
  final LostReportsRepository _repository;

  LostReportsCubit(this._repository) : super(LostReportsState.initial());

  /// Завантажує список активних SOS.
  Future<void> loadLostReports({
    String status = 'active',
  }) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      final reports = await _repository.getLostReports(status: status);

      emit(
        state.copyWith(
          isLoading: false,
          reports: reports,
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

  /// Завантажує одне SOS.
  Future<void> loadLostReportById(String reportId) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      final report = await _repository.getLostReportById(reportId);

      emit(
        state.copyWith(
          isLoading: false,
          selectedReport: report,
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

  /// Створює SOS.
  Future<void> createLostReport({
    required String petId,
    required double latitude,
    required double longitude,
    int? accuracyMeters,
    required String lastSeenAt,
    required String description,
    String? contactPhone,
    double? rewardAmount,
    int searchRadiusMeters = 3000,
  }) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      final report = await _repository.createLostReport(
        petId: petId,
        latitude: latitude,
        longitude: longitude,
        accuracyMeters: accuracyMeters,
        lastSeenAt: lastSeenAt,
        description: description,
        contactPhone: contactPhone,
        rewardAmount: rewardAmount,
        searchRadiusMeters: searchRadiusMeters,
      );

      final reports = await _repository.getLostReports();

      emit(
        state.copyWith(
          isLoading: false,
          reports: reports,
          selectedReport: report,
          successMessage: 'SOS-оголошення створено',
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

  /// Закриває SOS.
  Future<void> closeLostReport({
    required String reportId,
    required String closeReason,
    String? closeComment,
  }) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      final report = await _repository.closeLostReport(
        reportId: reportId,
        closeReason: closeReason,
        closeComment: closeComment,
      );

      final reports = await _repository.getLostReports();

      emit(
        state.copyWith(
          isLoading: false,
          reports: reports,
          selectedReport: report,
          successMessage: 'SOS-оголошення закрито',
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

  /// Очищення службових повідомлень.
  void clearMessages() {
    emit(
      state.copyWith(
        clearError: true,
        clearSuccess: true,
      ),
    );
  }
}