import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_section_card.dart';
import '../../data/models/pet_model.dart';
import '../cubit/pets_cubit.dart';
import '../cubit/pets_state.dart';

/// Екран деталей тварини.
/// Містить фото, характеристики, QR, SOS і службові дії власника.
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

  /// Вибирає фото з галереї та завантажує його у профіль.
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

  /// Підтверджує архівацію профілю тварини.
  Future<void> _confirmArchivePet() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Архівувати профіль?'),
          content: const Text(
            'Профіль тварини буде переміщено в архів. '
            'Для повідомлення про зникнення використовуйте функцію SOS.',
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

    if (confirmed != true || !mounted) {
      return;
    }

    await context.read<PetsCubit>().deletePet(widget.petId);

    if (!mounted) {
      return;
    }

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/pets');
    }
  }

  /// Підтверджує видалення фотографії.
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

    if (confirmed != true || !mounted) {
      return;
    }

    await context.read<PetsCubit>().deletePetPhoto(
          petId: widget.petId,
          photoId: photo.id,
        );
  }

  /// Відкриває форму SOS або повідомляє про вже активне оголошення.
  void _openSosAction(PetModel pet) {
    if (pet.status != 'lost') {
      context.push('/lost-reports/create/${widget.petId}');
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('SOS уже активне'),
          content: const Text(
            'Для цієї тварини вже існує активне SOS-оголошення. '
            'Друге оголошення створити неможливо.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Закрити'),
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PetsCubit, PetsState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
              ),
            );

          context.read<PetsCubit>().clearMessages();
        }

        if (state.successMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
              ),
            );

          context.read<PetsCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        final selectedPet = state.selectedPet;

        /// Не показуємо дані попередньої тварини,
        /// якщо Cubit ще завантажує новий профіль.
        final pet = selectedPet?.id == widget.petId
            ? selectedPet
            : null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Профіль тварини'),
            actions: [
              IconButton(
                onPressed: state.isLoading || pet == null
                    ? null
                    : () {
                        context.push('/pets/${widget.petId}/edit');
                      },
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Редагувати профіль',
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

              return Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _PetHeroCard(
                        pet: pet,
                        speciesLabel: _speciesLabel(pet.species),
                      ),

                      const SizedBox(height: 12),

                      AppSectionCard(
                        title: 'Фотографії',
                        icon: Icons.photo_library_outlined,
                        trailing: IconButton(
                          onPressed:
                              state.isLoading ? null : _pickAndUploadPhoto,
                          icon: const Icon(
                            Icons.add_photo_alternate_outlined,
                          ),
                          tooltip: 'Додати фото',
                        ),
                        child: pet.photos.isEmpty
                            ? _EmptyPhotosState(
                                onAddPhoto: state.isLoading
                                    ? null
                                    : _pickAndUploadPhoto,
                              )
                            : _PhotosGrid(
                                photos: pet.photos,
                                onSetMain: (photo) {
                                  context.read<PetsCubit>().setMainPhoto(
                                        petId: widget.petId,
                                        photoId: photo.id,
                                      );
                                },
                                onDelete: _confirmDeletePhoto,
                              ),
                      ),

                      const SizedBox(height: 12),

                      AppSectionCard(
                        title: 'Основні дії',
                        icon: Icons.widgets_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: () {
                                context.push('/pets/${widget.petId}/qr');
                              },
                              icon: const Icon(Icons.qr_code),
                              label: const Text('Показати QR-код'),
                            ),
                            const SizedBox(height: 10),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: pet.status == 'lost'
                                    ? Theme.of(context)
                                        .colorScheme
                                        .errorContainer
                                    : Theme.of(context).colorScheme.error,
                                foregroundColor: pet.status == 'lost'
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer
                                    : Theme.of(context).colorScheme.onError,
                              ),
                              onPressed: () {
                                _openSosAction(pet);
                              },
                              icon: const Icon(Icons.campaign),
                              label: Text(
                                pet.status == 'lost'
                                    ? 'SOS уже активне'
                                    : 'Створити SOS-оголошення',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      AppSectionCard(
                        title: 'Основна інформація',
                        icon: Icons.pets_outlined,
                        child: Column(
                          children: [
                            _InfoRow(
                              label: 'Вид',
                              value: _speciesLabel(pet.species),
                            ),
                            _InfoRow(
                              label: 'Порода',
                              value: pet.breed ?? 'Не вказано',
                            ),
                            _InfoRow(
                              label: 'Стать',
                              value: _genderLabel(pet.gender),
                            ),
                            _InfoRow(
                              label: 'Окрас',
                              value: pet.color,
                              showDivider: false,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      AppSectionCard(
                        title: 'Додаткові дані',
                        icon: Icons.badge_outlined,
                        child: Column(
                          children: [
                            _InfoRow(
                              label: 'Дата народження',
                              value: AppFormatters.dateFromIso(
                                pet.birthDate,
                              ),
                            ),
                            _InfoRow(
                              label: 'Вага',
                              value: pet.weightKg == null
                                  ? 'Не вказано'
                                  : '${pet.weightKg} кг',
                            ),
                            _InfoRow(
                              label: 'Номер чіпа',
                              value: pet.chipNumber ?? 'Не вказано',
                            ),
                            _InfoRow(
                              label: 'QR-профіль',
                              value: pet.isPublic
                                  ? 'Публічний'
                                  : 'Приватний',
                              showDivider: false,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      AppSectionCard(
                        title: 'Особливі прикмети',
                        icon: Icons.description_outlined,
                        child: Text(
                          pet.specialMarks?.trim().isNotEmpty == true
                              ? pet.specialMarks!
                              : 'Особливі прикмети не вказані.',
                        ),
                      ),

                      const SizedBox(height: 18),

                      TextButton.icon(
                        onPressed:
                            state.isLoading ? null : _confirmArchivePet,
                        style: TextButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.error,
                        ),
                        icon: const Icon(Icons.archive_outlined),
                        label: const Text('Архівувати профіль'),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),

                  if (state.isLoading)
                    Positioned.fill(
                      child: Container(
                        color: Theme.of(context)
                            .colorScheme
                            .scrim
                            .withOpacity(0.08),
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

/// Верхня картка профілю з головним фото, назвою та статусом.
class _PetHeroCard extends StatelessWidget {
  final PetModel pet;
  final String speciesLabel;

  const _PetHeroCard({
    required this.pet,
    required this.speciesLabel,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = AppConfig.buildFileUrl(pet.mainPhotoUrl);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 275,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photoUrl == null)
              Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.pets,
                  size: 84,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            else
              Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.pets,
                      size: 84,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                },
              ),

            Positioned(
              top: 12,
              left: 12,
              child: PetStatusBadge(
                status: pet.status,
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 46, 16, 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black87,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      pet.breed?.trim().isNotEmpty == true
                          ? '$speciesLabel • ${pet.breed}'
                          : speciesLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Порожній стан галереї.
class _EmptyPhotosState extends StatelessWidget {
  final VoidCallback? onAddPhoto;

  const _EmptyPhotosState({
    required this.onAddPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 42,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        const Text(
          'Фотографій ще немає',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Додайте чітке фото, щоб тварину було легше впізнати.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onAddPhoto,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Додати фото'),
        ),
      ],
    );
  }
}

/// Сітка фотографій тварини.
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 640 ? 4 : 3;

        return GridView.builder(
          itemCount: photos.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
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
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.image_not_supported_outlined),
                    )
                  else
                    Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: const Icon(Icons.image_not_supported_outlined),
                        );
                      },
                    ),

                  if (photo.isMain)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.58),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star,
                          size: 17,
                          color: Colors.amber,
                        ),
                      ),
                    ),

                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.54),
                        shape: BoxShape.circle,
                      ),
                      child: PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: 20,
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
                            PopupMenuItem(
                              value: 'main',
                              enabled: !photo.isMain,
                              child: Text(
                                photo.isMain
                                    ? 'Головне фото'
                                    : 'Зробити головним',
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Видалити'),
                            ),
                          ];
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Рядок характеристик профілю.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;

  const _InfoRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 132,
                child: Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
          ),
      ],
    );
  }
}