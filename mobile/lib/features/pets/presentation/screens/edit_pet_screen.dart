import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_section_card.dart';
import '../../data/models/pet_model.dart';
import '../cubit/pets_cubit.dart';
import '../cubit/pets_state.dart';

/// Екран редагування профілю тварини.
/// Статус тварини тут не змінюється, оскільки він залежить від SOS-сценарію.
class EditPetScreen extends StatefulWidget {
  final String petId;

  const EditPetScreen({
    super.key,
    required this.petId,
  });

  @override
  State<EditPetScreen> createState() => _EditPetScreenState();
}

class _EditPetScreenState extends State<EditPetScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _colorController = TextEditingController();
  final _weightController = TextEditingController();
  final _specialMarksController = TextEditingController();
  final _chipNumberController = TextEditingController();

  String _species = 'dog';
  String _gender = 'unknown';
  String _status = 'owned';

  DateTime? _birthDate;

  bool _isPublic = true;
  bool _showValidationErrors = false;
  bool _isFormInitialized = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cachedPet = context.read<PetsCubit>().state.selectedPet;

      if (cachedPet != null && cachedPet.id == widget.petId) {
        _fillForm(cachedPet);
      }

      context.read<PetsCubit>().loadPetById(widget.petId);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _colorController.dispose();
    _weightController.dispose();
    _specialMarksController.dispose();
    _chipNumberController.dispose();
    super.dispose();
  }

  /// Заповнює форму актуальними даними профілю.
  void _fillForm(PetModel pet) {
    if (_isFormInitialized) {
      return;
    }

    _nameController.text = pet.name;
    _breedController.text = pet.breed ?? '';
    _colorController.text = pet.color;
    _weightController.text = pet.weightKg?.toString() ?? '';
    _specialMarksController.text = pet.specialMarks ?? '';
    _chipNumberController.text = pet.chipNumber ?? '';

    final birthDateText = pet.birthDate?.split('T').first;

    setState(() {
      _species = pet.species;
      _gender = pet.gender;
      _status = pet.status;
      _birthDate = birthDateText == null
          ? null
          : DateTime.tryParse(birthDateText);
      _isPublic = pet.isPublic;
      _isFormInitialized = true;
      _loadFailed = false;
    });
  }

  /// Повертає дату у форматі, який очікує backend.
  String? _birthDateForApi() {
    final date = _birthDate;

    if (date == null) {
      return null;
    }

    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  /// Відкриває календар зміни дати народження.
  Future<void> _selectBirthDate() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _birthDate ??
          DateTime(
            now.year - 1,
            now.month,
            now.day,
          ),
      firstDate: DateTime(
        now.year - 50,
        now.month,
        now.day,
      ),
      lastDate: now,
      helpText: 'Оберіть дату народження',
      cancelText: 'Скасувати',
      confirmText: 'Підтвердити',
    );

    if (!mounted || selectedDate == null) {
      return;
    }

    setState(() {
      _birthDate = selectedDate;
    });
  }

  /// Перевіряє форму та зберігає зміни.
  Future<void> _updatePet() async {
    setState(() {
      _showValidationErrors = true;
    });

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Перевірте правильність заповнення полів'),
          ),
        );
      return;
    }

    final weightText = _weightController.text.trim().replaceAll(',', '.');

    await context.read<PetsCubit>().updatePet(
          petId: widget.petId,
          name: _nameController.text.trim(),
          species: _species,
          gender: _gender,
          color: _colorController.text.trim(),
          breed: _breedController.text.trim(),
          birthDate: _birthDateForApi(),
          weightKg: weightText.isEmpty
              ? null
              : double.tryParse(weightText),
          specialMarks: _specialMarksController.text.trim(),
          chipNumber: _chipNumberController.text.trim(),
          isPublic: _isPublic,
        );
  }

  IconData _speciesIcon() {
    switch (_species) {
      case 'bird':
        return Icons.flutter_dash_outlined;
      case 'rabbit':
        return Icons.cruelty_free_outlined;
      case 'dog':
      case 'cat':
      case 'rodent':
        return Icons.pets;
      default:
        return Icons.pets_outlined;
    }
  }

  String _speciesLabel() {
    switch (_species) {
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PetsCubit, PetsState>(
      listener: (context, state) {
        final pet = state.selectedPet;

        if (!_isFormInitialized && pet != null && pet.id == widget.petId) {
          _fillForm(pet);
        }

        if (state.errorMessage != null) {
          if (!_isFormInitialized) {
            setState(() {
              _loadFailed = true;
            });
          }

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
              ),
            );

          context.read<PetsCubit>().clearMessages();
        }

        if (state.successMessage == 'Профіль тварини оновлено') {
          context.read<PetsCubit>().clearMessages();

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Зміни збережено'),
              ),
            );

          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/pets/${widget.petId}');
          }
        }
      },
      builder: (context, state) {
        if (!_isFormInitialized) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Редагування профілю'),
            ),
            body: Center(
              child: _loadFailed
                  ? _LoadFailedState(
                      onRetry: () {
                        setState(() {
                          _loadFailed = false;
                        });

                        context
                            .read<PetsCubit>()
                            .loadPetById(widget.petId);
                      },
                    )
                  : const CircularProgressIndicator(),
            ),
          );
        }

        final isLoading = state.isLoading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Редагування профілю'),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 720,
                  ),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _showValidationErrors
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _EditProfileHeaderCard(
                          speciesIcon: _speciesIcon(),
                          speciesLabel: _speciesLabel(),
                          petName: _nameController.text.trim(),
                          status: _status,
                        ),

                        const SizedBox(height: 12),

                        AppSectionCard(
                          title: 'Основна інформація',
                          icon: Icons.pets_outlined,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Кличка',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (_) {
                                  setState(() {});
                                },
                                validator: (value) {
                                  final text = value?.trim() ?? '';

                                  if (text.isEmpty) {
                                    return 'Кличка є обовʼязковою';
                                  }

                                  if (text.length < 2) {
                                    return 'Кличка має містити мінімум 2 символи';
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 12),

                              DropdownButtonFormField<String>(
                                initialValue: _species,
                                decoration: const InputDecoration(
                                  labelText: 'Вид тварини',
                                  prefixIcon: Icon(Icons.category_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'dog',
                                    child: Text('Собака'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'cat',
                                    child: Text('Кіт'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'bird',
                                    child: Text('Птах'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'rabbit',
                                    child: Text('Кролик'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'rodent',
                                    child: Text('Гризун'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'other',
                                    child: Text('Інше'),
                                  ),
                                ],
                                onChanged: isLoading
                                    ? null
                                    : (value) {
                                        if (value == null) {
                                          return;
                                        }

                                        setState(() {
                                          _species = value;
                                        });
                                      },
                              ),

                              const SizedBox(height: 12),

                              TextFormField(
                                controller: _breedController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Порода',
                                  hintText: 'Необовʼязково',
                                  prefixIcon: Icon(Icons.info_outline),
                                  border: OutlineInputBorder(),
                                ),
                              ),

                              const SizedBox(height: 12),

                              DropdownButtonFormField<String>(
                                initialValue: _gender,
                                decoration: const InputDecoration(
                                  labelText: 'Стать',
                                  prefixIcon: Icon(Icons.wc_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'male',
                                    child: Text('Самець'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'female',
                                    child: Text('Самка'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'unknown',
                                    child: Text('Невідомо'),
                                  ),
                                ],
                                onChanged: isLoading
                                    ? null
                                    : (value) {
                                        if (value == null) {
                                          return;
                                        }

                                        setState(() {
                                          _gender = value;
                                        });
                                      },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        AppSectionCard(
                          title: 'Зовнішній вигляд',
                          icon: Icons.visibility_outlined,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _colorController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Окрас',
                                  prefixIcon: Icon(Icons.palette_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  final text = value?.trim() ?? '';

                                  if (text.isEmpty) {
                                    return 'Окрас є обовʼязковим';
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 12),

                              TextFormField(
                                controller: _specialMarksController,
                                minLines: 3,
                                maxLines: 5,
                                decoration: const InputDecoration(
                                  labelText: 'Особливі прикмети',
                                  hintText:
                                      'Пляма біля ока, нашийник, шрам тощо',
                                  prefixIcon: Icon(Icons.description_outlined),
                                  border: OutlineInputBorder(),
                                  alignLabelWithHint: true,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        AppSectionCard(
                          title: 'Додаткові дані',
                          icon: Icons.assignment_ind_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _weightController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Вага',
                                  hintText: 'Необовʼязково',
                                  prefixIcon: Icon(
                                    Icons.monitor_weight_outlined,
                                  ),
                                  suffixText: 'кг',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  final text = value
                                          ?.trim()
                                          .replaceAll(',', '.') ??
                                      '';

                                  if (text.isEmpty) {
                                    return null;
                                  }

                                  final number = double.tryParse(text);

                                  if (number == null) {
                                    return 'Вага має бути числом';
                                  }

                                  if (number <= 0 || number > 300) {
                                    return 'Введіть коректну вагу';
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 12),

                              Card(
                                margin: EdgeInsets.zero,
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLow,
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.calendar_month_outlined,
                                  ),
                                  title: const Text('Дата народження'),
                                  subtitle: Text(
                                    _birthDate == null
                                        ? 'Не вказано'
                                        : AppFormatters.dateFromIso(
                                            _birthDateForApi(),
                                          ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_birthDate != null)
                                        IconButton(
                                          onPressed: isLoading
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _birthDate = null;
                                                  });
                                                },
                                          icon: const Icon(Icons.clear),
                                          tooltip: 'Очистити дату',
                                        ),
                                      IconButton(
                                        onPressed: isLoading
                                            ? null
                                            : _selectBirthDate,
                                        icon: const Icon(Icons.edit_outlined),
                                        tooltip: 'Змінити дату',
                                      ),
                                    ],
                                  ),
                                  onTap: isLoading
                                      ? null
                                      : _selectBirthDate,
                                ),
                              ),

                              const SizedBox(height: 12),

                              TextFormField(
                                controller: _chipNumberController,
                                textInputAction: TextInputAction.done,
                                decoration: const InputDecoration(
                                  labelText: 'Номер чіпа',
                                  hintText: 'Необовʼязково',
                                  prefixIcon: Icon(Icons.memory_outlined),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        AppSectionCard(
                          title: 'QR-профіль',
                          icon: Icons.qr_code_outlined,
                          child: SwitchListTile(
                            value: _isPublic,
                            contentPadding: EdgeInsets.zero,
                            secondary: Icon(
                              _isPublic
                                  ? Icons.public_outlined
                                  : Icons.lock_outline,
                            ),
                            title: Text(
                              _isPublic
                                  ? 'Публічний профіль увімкнено'
                                  : 'Профіль приховано',
                            ),
                            subtitle: Text(
                              _isPublic
                                  ? 'Безпечні дані тварини доступні через QR-посилання без входу.'
                                  : 'Публічний перегляд профілю через QR буде вимкнено.',
                            ),
                            onChanged: isLoading
                                ? null
                                : (value) {
                                    setState(() {
                                      _isPublic = value;
                                    });
                                  },
                          ),
                        ),

                        const SizedBox(height: 12),

                        Card(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Фото та статус тварини змінюються '
                                    'окремими діями у профілі. '
                                    'Статус «Зникла» керується через SOS-пошук.',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        FilledButton.icon(
                          onPressed: isLoading ? null : _updatePet,
                          icon: isLoading
                              ? const SizedBox(
                                  width: 19,
                                  height: 19,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            isLoading
                                ? 'Збереження...'
                                : 'Зберегти зміни',
                          ),
                        ),

                        const SizedBox(height: 10),

                        OutlinedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  context.pop();
                                },
                          child: const Text('Скасувати'),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Верхній блок редагування профілю.
class _EditProfileHeaderCard extends StatelessWidget {
  final IconData speciesIcon;
  final String speciesLabel;
  final String petName;
  final String status;

  const _EditProfileHeaderCard({
    required this.speciesIcon,
    required this.speciesLabel,
    required this.petName,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                speciesIcon,
                color: colors.onPrimary,
                size: 32,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    petName.isEmpty ? 'Профіль тварини' : petName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$speciesLabel • Редагування профілю',
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 10),
                  PetStatusBadge(
                    status: status,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Стан помилки під час завантаження профілю.
class _LoadFailedState extends StatelessWidget {
  final VoidCallback onRetry;

  const _LoadFailedState({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 66,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 14),
          const Text(
            'Не вдалося завантажити профіль',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Перевірте підключення до сервера та спробуйте ще раз.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Повторити'),
          ),
        ],
      ),
    );
  }
}