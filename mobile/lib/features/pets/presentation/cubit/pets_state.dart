import 'package:equatable/equatable.dart';

import '../../data/models/pet_model.dart';

/// Стан модуля тварин.
class PetsState extends Equatable {
  final bool isLoading;
  final List<PetModel> pets;
  final PetModel? selectedPet;
  final String? errorMessage;
  final String? successMessage;

  const PetsState({
    required this.isLoading,
    required this.pets,
    required this.selectedPet,
    required this.errorMessage,
    required this.successMessage,
  });

  factory PetsState.initial() {
    return const PetsState(
      isLoading: false,
      pets: [],
      selectedPet: null,
      errorMessage: null,
      successMessage: null,
    );
  }

  PetsState copyWith({
    bool? isLoading,
    List<PetModel>? pets,
    PetModel? selectedPet,
    bool clearSelectedPet = false,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return PetsState(
      isLoading: isLoading ?? this.isLoading,
      pets: pets ?? this.pets,
      selectedPet: clearSelectedPet ? null : selectedPet ?? this.selectedPet,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        pets,
        selectedPet,
        errorMessage,
        successMessage,
      ];
}