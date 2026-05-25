import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/app_section_card.dart';
import '../cubit/pets_cubit.dart';
import '../cubit/pets_state.dart';

/// Екран створення профілю тварини.
/// Після збереження користувач переходить до нового профілю,
/// де може додати фотографії та створити QR-код.
class CreatePetScreen extends StatefulWidget {
  const CreatePetScreen({super.key});

  @override
  State<CreatePetScreen> createState() => _CreatePetScreenState();
}

class _CreatePetScreenState extends State<CreatePetScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _colorController = TextEditingController();
  final _weightController = TextEditingController();
  final _specialMarksController = TextEditingController();
  final _chipNumberController = TextEditingController();

  String _species = 'dog';
  String _gender = 'unknown';
  DateTime? _birthDate;

  bool _isPublic = true;
  bool _showValidationErrors = false;

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

  /// Відкриває календар вибору дати народження.
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

  /// Перевіряє форму та створює профіль тварини.
  Future<void> _createPet() async {
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

    await context.read<PetsCubit>().createPet(
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
      case 'dog':
        return Icons.pets;
      case 'cat':
        return Icons.pets;
      case 'bird':
        return Icons.flutter_dash_outlined;
      case 'rabbit':
        return Icons.cruelty_free_outlined;
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
        if (state.successMessage == 'Профіль тварини створено') {
          final petId = state.selectedPet?.id;

          context.read<PetsCubit>().clearMessages();

          if (petId != null && petId.isNotEmpty) {
            context.pushReplacement('/pets/$petId');
          } else {
            context.go('/pets');
          }
        }

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
      },
      builder: (context, state) {
        final isLoading = state.isLoading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Новий профіль'),
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
                        _CreateProfileHeaderCard(
                          speciesIcon: _speciesIcon(),
                          speciesLabel: _speciesLabel(),
                          petName: _nameController.text.trim(),
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
                                  hintText: 'Наприклад: Боня',
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
                                  hintText: 'Білий з коричневими плямами',
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
                                        tooltip: 'Обрати дату',
                                      ),
                                    ],
                                  ),
                                  onTap:
                                      isLoading ? null : _selectBirthDate,
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
                          child: Column(
                            children: [
                              SwitchListTile(
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
                                      ? 'Після створення QR-коду безпечні дані тварини можна буде переглянути без входу.'
                                      : 'QR-посилання не повинно показувати дані тварини стороннім користувачам.',
                                ),
                                onChanged: isLoading
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _isPublic = value;
                                        });
                                      },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        Card(
                          color: Theme.of(context)
                              .colorScheme
                              .secondaryContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Фотографії додаються після створення профілю. '
                                    'Після збереження ви одразу перейдете до сторінки тварини.',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSecondaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        FilledButton.icon(
                          onPressed: isLoading ? null : _createPet,
                          icon: isLoading
                              ? const SizedBox(
                                  width: 19,
                                  height: 19,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: Text(
                            isLoading
                                ? 'Створення профілю...'
                                : 'Створити профіль',
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          'Після створення можна буде додати фото, '
                          'створити QR-код та за потреби опублікувати SOS.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
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

/// Верхній інформаційний блок створення профілю.
class _CreateProfileHeaderCard extends StatelessWidget {
  final IconData speciesIcon;
  final String speciesLabel;
  final String petName;

  const _CreateProfileHeaderCard({
    required this.speciesIcon,
    required this.speciesLabel,
    required this.petName,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final displayName = petName.isEmpty
        ? 'Нова тварина'
        : petName;

    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
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
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$speciesLabel • Новий профіль',
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                    ),
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