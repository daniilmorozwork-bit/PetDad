import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/app_config.dart';
import '../../data/models/pet_model.dart';
import '../cubit/pets_cubit.dart';
import '../cubit/pets_state.dart';
import 'package:go_router/go_router.dart';

/// Екран деталей тварини.
class PetDetailsScreen extends StatefulWidget {
  final String petId;

  const PetDetailsScreen({
    super.key,
    required this.petId,
  });

  @override
  State<PetDetailsScreen> createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends State<PetDetailsScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PetsCubit>().loadPetById(widget.petId);
    });
  }

  Future<void> _pickAndUploadPhoto() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile == null) {
      return;
    }

    final bytes = await pickedFile.readAsBytes();

    if (!mounted) {
      return;
    }

    await context.read<PetsCubit>().uploadPetPhoto(
          petId: widget.petId,
          bytes: bytes,
          fileName: pickedFile.name,
        );
  }

  Future<void> _confirmDeletePet() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Архівувати профіль?'),
          content: const Text(
            'Профіль тварини буде архівовано. Для SOS-пошуку використовуйте окрему дію “Створити SOS”.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Скасувати'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Архівувати'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    await context.read<PetsCubit>().deletePet(widget.petId);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmDeletePhoto(PetPhotoModel photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Видалити фото?'),
          content: const Text(
            'Фото буде видалено з профілю тварини.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Скасувати'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Видалити'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    await context.read<PetsCubit>().deletePetPhoto(
          petId: widget.petId,
          photoId: photo.id,
        );
  }

  String _speciesLabel(String species) {
    switch (species) {
      case 'dog':
        return 'Собака';
      case 'cat':
        return 'Кіт';
      case 'bird':
        return 'Птах';
      case 'rabbit':
        return 'Кролик';
      case 'rodent':
        return 'Гризун';
      default:
        return 'Інше';
    }
  }

  String _genderLabel(String gender) {
    switch (gender) {
      case 'male':
        return 'Самець';
      case 'female':
        return 'Самка';
      default:
        return 'Невідомо';
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'owned':
        return 'Вдома';
      case 'lost':
        return 'Зникла';
      case 'found':
        return 'Знайдена';
      case 'archived':
        return 'Архів';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PetsCubit, PetsState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );

          context.read<PetsCubit>().clearMessages();
        }

        if (state.successMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(state.successMessage!)),
            );

          context.read<PetsCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        final pet = state.selectedPet;

        return Scaffold(
          appBar: AppBar(
            title: Text(pet?.name ?? 'Профіль тварини'),
            actions: [
              IconButton(
                onPressed: state.isLoading ? null : _confirmDeletePet,
                icon: const Icon(Icons.archive_outlined),
                tooltip: 'Архівувати',
              ),
            ],
          ),
          body: Builder(
            builder: (context) {
              if (state.isLoading && pet == null) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (pet == null) {
                return const Center(
                  child: Text('Тварину не знайдено'),
                );
              }

              final photoUrl = AppConfig.buildFileUrl(pet.mainPhotoUrl);

              return Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          height: 220,
                          child: photoUrl == null
                              ? Container(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  child: const Center(
                                    child: Icon(Icons.pets, size: 72),
                                  ),
                                )
                              : Image.network(
                                  photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      child: const Center(
                                        child: Icon(Icons.pets, size: 72),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      OutlinedButton.icon(
                        onPressed: state.isLoading ? null : _pickAndUploadPhoto,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Додати фото'),
                      ),

                      if (pet.photos.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Фото',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _PhotosGrid(
                          photos: pet.photos,
                          onSetMain: (photo) {
                            context.read<PetsCubit>().setMainPhoto(
                                  petId: widget.petId,
                                  photoId: photo.id,
                                );
                          },
                          onDelete: _confirmDeletePhoto,
                        ),
                      ],

                      const SizedBox(height: 20),

                      Text(
                        pet.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),

                      Chip(
                        label: Text(_statusLabel(pet.status)),
                      ),
                      const SizedBox(height: 16),

                      _InfoRow(label: 'Вид', value: _speciesLabel(pet.species)),
                      _InfoRow(label: 'Порода', value: pet.breed ?? 'Не вказано'),
                      _InfoRow(label: 'Стать', value: _genderLabel(pet.gender)),
                      _InfoRow(label: 'Окрас', value: pet.color),
                      _InfoRow(
                        label: 'Вага',
                        value: pet.weightKg == null
                            ? 'Не вказано'
                            : '${pet.weightKg} кг',
                      ),
                      _InfoRow(
                        label: 'Дата народження',
                        value: pet.birthDate ?? 'Не вказано',
                      ),
                      _InfoRow(
                        label: 'Номер чіпа',
                        value: pet.chipNumber ?? 'Не вказано',
                      ),
                      _InfoRow(
                        label: 'Особливі прикмети',
                        value: pet.specialMarks ?? 'Не вказано',
                      ),

                      const SizedBox(height: 24),

                      FilledButton.icon(
                        onPressed: () {
                          context.push('/pets/${widget.petId}/qr');
                        },
                        icon: const Icon(Icons.qr_code),
                        label: const Text('QR-код'),
                      ),
                      const SizedBox(height: 8),

                     OutlinedButton.icon(
                      onPressed: () {
                        if (pet.status == 'lost') {
                          showDialog<void>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('SOS уже активне'),
                                content: const Text(
                                  'Для цієї тварини вже створено активне SOS-оголошення. Неможливо створити друге SOS для тварини зі статусом “зникла”.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Зрозуміло'),
                                  ),
                                  FilledButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      context.push('/lost-reports');
                                    },
                                    child: const Text('Перейти до SOS'),
                                  ),
                                ],
                              );
                            },
                          );

                          return;
                        }

                        context.push('/lost-reports/create/${widget.petId}');
                      },
                      icon: const Icon(Icons.campaign_outlined),
                      label: Text(
                        pet.status == 'lost' ? 'SOS уже активне' : 'Створити SOS',
                      ),
                    ),
                    ],
                  ),

                  if (state.isLoading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.08),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// Сітка фото тварини.
class _PhotosGrid extends StatelessWidget {
  final List<PetPhotoModel> photos;
  final ValueChanged<PetPhotoModel> onSetMain;
  final ValueChanged<PetPhotoModel> onDelete;

  const _PhotosGrid({
    required this.photos,
    required this.onSetMain,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: photos.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final photo = photos[index];
        final url = AppConfig.buildFileUrl(photo.file.url);

        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (url == null)
                Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.image_not_supported_outlined),
                )
              else
                Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.image_not_supported_outlined),
                    );
                  },
                ),

              if (photo.isMain)
                const Positioned(
                  left: 6,
                  top: 6,
                  child: Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                ),

              Positioned(
                right: 0,
                top: 0,
                child: PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                  ),
                  onSelected: (value) {
                    if (value == 'main') {
                      onSetMain(photo);
                    }

                    if (value == 'delete') {
                      onDelete(photo);
                    }
                  },
                  itemBuilder: (context) {
                    return [
                      const PopupMenuItem(
                        value: 'main',
                        child: Text('Зробити головним'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Видалити'),
                      ),
                    ];
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Рядок характеристики тварини.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}