import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/pet_model.dart';
import '../cubit/pets_cubit.dart';
import '../cubit/pets_state.dart';

/// Екран редагування профілю тварини.
/// Статус тварини тут не редагується, оскільки він залежить від SOS-сценарію.
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
  final _birthDateController = TextEditingController();
  final _colorController = TextEditingController();
  final _weightController = TextEditingController();
  final _specialMarksController = TextEditingController();
  final _chipNumberController = TextEditingController();

  String _species = 'dog';
  String _gender = 'unknown';
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
    _birthDateController.dispose();
    _colorController.dispose();
    _weightController.dispose();
    _specialMarksController.dispose();
    _chipNumberController.dispose();
    super.dispose();
  }

  /// Заповнює форму даними завантаженої тварини.
  void _fillForm(PetModel pet) {
    if (_isFormInitialized) {
      return;
    }

    _nameController.text = pet.name;
    _breedController.text = pet.breed ?? '';
    _birthDateController.text = pet.birthDate?.split('T').first ?? '';
    _colorController.text = pet.color;
    _weightController.text = pet.weightKg?.toString() ?? '';
    _specialMarksController.text = pet.specialMarks ?? '';
    _chipNumberController.text = pet.chipNumber ?? '';

    setState(() {
      _species = pet.species;
      _gender = pet.gender;
      _isPublic = pet.isPublic;
      _isFormInitialized = true;
      _loadFailed = false;
    });
  }

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

    await context.read<PetsCubit>().updatePet(
          petId: widget.petId,
          name: _nameController.text.trim(),
          species: _species,
          gender: _gender,
          color: _colorController.text.trim(),
          breed: _breedController.text.trim(),
          birthDate: _birthDateController.text.trim().isEmpty
              ? null
              : _birthDateController.text.trim(),
          weightKg: _weightController.text.trim().isEmpty
              ? null
              : double.tryParse(_weightController.text.trim()),
          specialMarks: _specialMarksController.text.trim(),
          chipNumber: _chipNumberController.text.trim(),
          isPublic: _isPublic,
        );
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
              SnackBar(content: Text(state.errorMessage!)),
            );

          context.read<PetsCubit>().clearMessages();
        }

        if (state.successMessage == 'Профіль тварини оновлено') {
          context.read<PetsCubit>().clearMessages();

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
              title: const Text('Редагувати профіль'),
            ),
            body: Center(
              child: _loadFailed
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Не вдалося завантажити дані тварини'),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _loadFailed = false;
                            });

                            context
                                .read<PetsCubit>()
                                .loadPetById(widget.petId);
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Повторити'),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(),
            ),
          );
        }

        final isLoading = state.isLoading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Редагувати профіль'),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                autovalidateMode: _showValidationErrors
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Основна інформація',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Кличка',
                        border: OutlineInputBorder(),
                      ),
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
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'dog', child: Text('Собака')),
                        DropdownMenuItem(value: 'cat', child: Text('Кіт')),
                        DropdownMenuItem(value: 'bird', child: Text('Птах')),
                        DropdownMenuItem(
                          value: 'rabbit',
                          child: Text('Кролик'),
                        ),
                        DropdownMenuItem(
                          value: 'rodent',
                          child: Text('Гризун'),
                        ),
                        DropdownMenuItem(value: 'other', child: Text('Інше')),
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
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: const InputDecoration(
                        labelText: 'Стать',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Самець')),
                        DropdownMenuItem(value: 'female', child: Text('Самка')),
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
                    const SizedBox(height: 24),

                    const Text(
                      'Опис тварини',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _colorController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Окрас',
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
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Вага, кг',
                        hintText: 'Необовʼязково',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';

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

                    TextFormField(
                      controller: _birthDateController,
                      keyboardType: TextInputType.datetime,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Дата народження',
                        hintText: 'YYYY-MM-DD',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';

                        if (text.isEmpty) {
                          return null;
                        }

                        final date = DateTime.tryParse(text);

                        if (date == null) {
                          return 'Дата має бути у форматі YYYY-MM-DD';
                        }

                        if (date.isAfter(DateTime.now())) {
                          return 'Дата не може бути в майбутньому';
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
                        hintText: 'Пляма, нашийник, шрам тощо',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _chipNumberController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Номер чіпа',
                        hintText: 'Необовʼязково',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SwitchListTile(
                      value: _isPublic,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Публічний профіль'),
                      subtitle: const Text(
                        'Дозволяє показувати безпечні дані через QR-код',
                      ),
                      onChanged: isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _isPublic = value;
                              });
                            },
                    ),
                    const SizedBox(height: 20),

                    FilledButton.icon(
                      onPressed: isLoading ? null : _updatePet,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(
                        isLoading ? 'Збереження...' : 'Зберегти зміни',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}