import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/qr_repository.dart';
import 'qr_state.dart';

/// Cubit для QR-кодів.
class QrCubit extends Cubit<QrState> {
  final QrRepository _qrRepository;

  QrCubit(this._qrRepository) : super(QrState.initial());

  /// Завантажує активний QR-код.
  Future<void> loadActiveQr(String petId) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccess: true,
        clearQrCode: true,
      ),
    );

    try {
      final qrCode = await _qrRepository.getActiveQrForPet(petId);

      emit(
        state.copyWith(
          isLoading: false,
          qrCode: qrCode,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          clearQrCode: true,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  /// Створює QR-код.
  Future<void> generateQr(String petId) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      final qrCode = await _qrRepository.generateQrForPet(petId);

      emit(
        state.copyWith(
          isLoading: false,
          qrCode: qrCode,
          successMessage: 'QR-код створено',
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

  /// Перевипускає QR-код.
  Future<void> reissueQr(String petId) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      final qrCode = await _qrRepository.reissueQrForPet(petId);

      emit(
        state.copyWith(
          isLoading: false,
          qrCode: qrCode,
          successMessage: 'QR-код перевипущено',
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

  /// Завантажує публічний профіль за token.
  Future<void> loadPublicProfile(String token) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccess: true,
        clearPublicProfile: true,
      ),
    );

    try {
      final profile = await _qrRepository.getPublicPetProfile(token);

      emit(
        state.copyWith(
          isLoading: false,
          publicProfile: profile,
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

  /// Реєструє сканування QR.
  Future<void> registerScan(String token) async {
    try {
      await _qrRepository.registerScan(token: token);
    } catch (_) {
      /// Для публічного перегляду не блокуємо UI, якщо логування сканування не вдалося.
    }
  }

  /// Очищає службові повідомлення.
  void clearMessages() {
    emit(
      state.copyWith(
        clearError: true,
        clearSuccess: true,
      ),
    );
  }
}