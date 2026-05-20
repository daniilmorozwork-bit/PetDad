import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/pets_repository.dart';
import 'pets_state.dart';

/// Cubit для роботи з тваринами.
class PetsCubit extends Cubit<PetsState> {
  final PetsRepository _petsRepository;

  PetsCubit(this._petsRepository) : super(PetsState.initial());

  /// Завантажує список тварин користувача.
  Future<void> loadMyPets() async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      final pets = await _petsRepository.getMyPets();

      emit(
        state.copyWith(
          isLoading: false,
          pets: pets,
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

  /// Завантажує деталі тварини.
  Future<void> loadPetById(String petId) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      final pet = await _petsRepository.getPetById(petId);

      emit(
        state.copyWith(
          isLoading: false,
          selectedPet: pet,
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

  /// Створює профіль тварини.
  Future<void> createPet({
    required String name,
    required String species,
    required String gender,
    required String color,
    String? breed,
    String? birthDate,
    double? weightKg,
    String? specialMarks,
    String? chipNumber,
    bool isPublic = true,
  }) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      await _petsRepository.createPet(
        name: name,
        species: species,
        gender: gender,
        color: color,
        breed: breed,
        birthDate: birthDate,
        weightKg: weightKg,
        specialMarks: specialMarks,
        chipNumber: chipNumber,
        isPublic: isPublic,
      );

      final pets = await _petsRepository.getMyPets();

      emit(
        state.copyWith(
          isLoading: false,
          pets: pets,
          successMessage: 'Профіль тварини створено',
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

  /// Завантажує фото тварини.
  Future<void> uploadPetPhoto({
    required String petId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      await _petsRepository.uploadPetPhoto(
        petId: petId,
        bytes: bytes,
        fileName: fileName,
      );

      final pet = await _petsRepository.getPetById(petId);
      final pets = await _petsRepository.getMyPets();

      emit(
        state.copyWith(
          isLoading: false,
          selectedPet: pet,
          pets: pets,
          successMessage: 'Фото додано',
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

  /// Робить фото головним.
  Future<void> setMainPhoto({
    required String petId,
    required String photoId,
  }) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      await _petsRepository.setMainPhoto(
        petId: petId,
        photoId: photoId,
      );

      final pet = await _petsRepository.getPetById(petId);
      final pets = await _petsRepository.getMyPets();

      emit(
        state.copyWith(
          isLoading: false,
          selectedPet: pet,
          pets: pets,
          successMessage: 'Головне фото оновлено',
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

  /// Видаляє фото тварини.
  Future<void> deletePetPhoto({
    required String petId,
    required String photoId,
  }) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      await _petsRepository.deletePetPhoto(
        petId: petId,
        photoId: photoId,
      );

      final pet = await _petsRepository.getPetById(petId);
      final pets = await _petsRepository.getMyPets();

      emit(
        state.copyWith(
          isLoading: false,
          selectedPet: pet,
          pets: pets,
          successMessage: 'Фото видалено',
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

  /// Архівує тварину.
  Future<void> deletePet(String petId) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      await _petsRepository.deletePet(petId);

      final pets = await _petsRepository.getMyPets();

      emit(
        state.copyWith(
          isLoading: false,
          pets: pets,
          clearSelectedPet: true,
          successMessage: 'Профіль тварини архівовано',
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

  /// Очищає службові повідомлення, щоб SnackBar не дублювався.
  void clearMessages() {
    emit(
      state.copyWith(
        clearError: true,
        clearSuccess: true,
      ),
    );
  }
}