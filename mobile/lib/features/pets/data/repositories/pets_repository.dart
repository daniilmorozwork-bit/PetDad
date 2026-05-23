import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../../core/api/api_client.dart';
import '../models/pet_model.dart';

/// Repository для роботи з профілями тварин.
class PetsRepository {
  final ApiClient _apiClient;

  PetsRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  /// Повертає список тварин поточного користувача.
  Future<List<PetModel>> getMyPets() async {
    try {
      final response = await _apiClient.dio.get('/pets/my');

      final data = response.data as List<dynamic>;

      return data
          .map((item) => PetModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  /// Повертає одну тварину за id.
  Future<PetModel> getPetById(String petId) async {
    try {
      final response = await _apiClient.dio.get('/pets/$petId');

      return PetModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  /// Створює профіль тварини.
  Future<PetModel> createPet({
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
    try {
      final response = await _apiClient.dio.post(
        '/pets',
        data: {
          'name': name.trim(),
          'species': species,
          'breed': _emptyToNull(breed),
          'gender': gender,
          'birthDate': _emptyToNull(birthDate),
          'color': color.trim(),
          'weightKg': weightKg,
          'specialMarks': _emptyToNull(specialMarks),
          'chipNumber': _emptyToNull(chipNumber),
          'isPublic': isPublic,
        },
      );

      return PetModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

    /// Оновлює основні дані профілю тварини.
  Future<PetModel> updatePet({
    required String petId,
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
    try {
      final response = await _apiClient.dio.patch(
        '/pets/$petId',
        data: {
          'name': name.trim(),
          'species': species,
          'breed': _emptyToNull(breed),
          'gender': gender,
          'birthDate': _emptyToNull(birthDate),
          'color': color.trim(),
          'weightKg': weightKg,
          'specialMarks': _emptyToNull(specialMarks),
          'chipNumber': _emptyToNull(chipNumber),
          'isPublic': isPublic,
        },
      );

      return PetModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  /// Завантажує фото тварини.
  Future<PetPhotoModel> uploadPetPhoto({
    required String petId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: _detectMediaType(fileName),
        ),
      });

      final response = await _apiClient.dio.post(
        '/pets/$petId/photos',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      return PetPhotoModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  /// Робить фото головним.
  Future<PetPhotoModel> setMainPhoto({
    required String petId,
    required String photoId,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        '/pets/$petId/photos/$photoId/main',
      );

      return PetPhotoModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  /// Видаляє фото тварини.
  Future<void> deletePetPhoto({
    required String petId,
    required String photoId,
  }) async {
    try {
      await _apiClient.dio.delete('/pets/$petId/photos/$photoId');
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  /// Архівує профіль тварини.
  Future<void> deletePet(String petId) async {
    try {
      await _apiClient.dio.delete('/pets/$petId');
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();

    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  /// Визначає MIME-тип за назвою файлу.
  MediaType _detectMediaType(String fileName) {
    final lowerName = fileName.toLowerCase();

    if (lowerName.endsWith('.png')) {
      return MediaType('image', 'png');
    }

    if (lowerName.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }

    return MediaType('image', 'jpeg');
  }

  Exception _handleDioError(DioException error) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message'];

      if (message is String) {
        return Exception(message);
      }

      if (message is List) {
        return Exception(message.join('\n'));
      }
    }

    if (error.type == DioExceptionType.connectionError) {
      return Exception(
        'Не вдалося підключитися до сервера. Перевірте, чи запущений backend.',
      );
    }

    return Exception('Сталася помилка запиту');
  }
}