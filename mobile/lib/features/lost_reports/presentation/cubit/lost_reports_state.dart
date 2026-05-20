import 'package:equatable/equatable.dart';

import '../../data/models/lost_report_model.dart';

/// Стан SOS-модуля.
class LostReportsState extends Equatable {
  final bool isLoading;
  final List<LostReportModel> reports;
  final LostReportModel? selectedReport;
  final String? errorMessage;
  final String? successMessage;

  const LostReportsState({
    required this.isLoading,
    required this.reports,
    required this.selectedReport,
    required this.errorMessage,
    required this.successMessage,
  });

  factory LostReportsState.initial() {
    return const LostReportsState(
      isLoading: false,
      reports: [],
      selectedReport: null,
      errorMessage: null,
      successMessage: null,
    );
  }

  LostReportsState copyWith({
    bool? isLoading,
    List<LostReportModel>? reports,
    LostReportModel? selectedReport,
    bool clearSelectedReport = false,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return LostReportsState(
      isLoading: isLoading ?? this.isLoading,
      reports: reports ?? this.reports,
      selectedReport:
          clearSelectedReport ? null : selectedReport ?? this.selectedReport,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        reports,
        selectedReport,
        errorMessage,
        successMessage,
      ];
}