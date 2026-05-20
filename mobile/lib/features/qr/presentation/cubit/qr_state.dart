import 'package:equatable/equatable.dart';

import '../../data/models/public_pet_profile_model.dart';
import '../../data/models/qr_code_model.dart';

/// Стан QR-модуля.
class QrState extends Equatable {
  final bool isLoading;
  final QrCodeModel? qrCode;
  final PublicPetProfileModel? publicProfile;
  final String? errorMessage;
  final String? successMessage;

  const QrState({
    required this.isLoading,
    required this.qrCode,
    required this.publicProfile,
    required this.errorMessage,
    required this.successMessage,
  });

  factory QrState.initial() {
    return const QrState(
      isLoading: false,
      qrCode: null,
      publicProfile: null,
      errorMessage: null,
      successMessage: null,
    );
  }

  QrState copyWith({
    bool? isLoading,
    QrCodeModel? qrCode,
    bool clearQrCode = false,
    PublicPetProfileModel? publicProfile,
    bool clearPublicProfile = false,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return QrState(
      isLoading: isLoading ?? this.isLoading,
      qrCode: clearQrCode ? null : qrCode ?? this.qrCode,
      publicProfile:
          clearPublicProfile ? null : publicProfile ?? this.publicProfile,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        qrCode,
        publicProfile,
        errorMessage,
        successMessage,
      ];
}