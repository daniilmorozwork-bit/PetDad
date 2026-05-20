import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubit/pets_cubit.dart';
import '../cubit/pets_state.dart';

/// Екран створення профілю тварини.
class CreatePetScreen extends StatefulWidget {
  const CreatePetScreen({super.key});

  @override
  State<CreatePetScreen> createState() => _CreatePetScreenState();
}

class _CreatePetScreenState extends State<CreatePetScreen> {
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

    await context.read<PetsCubit>().createPet(
          name: _nameController.text,
          species: _species,
          gender: _gender,
          color: _colorController.text,
          breed: _breedController.text,
          birthDate: _birthDateController.text.trim().isEmpty
              ? null
              : _birthDateController.text.trim(),
          weightKg: _weightController.text.trim().isEmpty
              ? null
              : double.tryParse(_weightController.text.trim()),
          specialMarks: _specialMarksController.text,
          chipNumber: _chipNumberController.text,
          isPublic: _isPublic,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PetsCubit, PetsState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          context.read<PetsCubit>().clearMessages();
          context.go('/pets');
        }

        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );

          context.read<PetsCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        final isLoading = state.isLoading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Додати тварину'),
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
                        hintText: 'Наприклад: Боня',
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
                      value: _species,
                      decoration: const InputDecoration(
                        labelText: 'Вид тварини',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'dog', child: Text('Собака')),
                        DropdownMenuItem(value: 'cat', child: Text('Кіт')),
                        DropdownMenuItem(value: 'bird', child: Text('Птах')),
                        DropdownMenuItem(value: 'rabbit', child: Text('Кролик')),
                        DropdownMenuItem(value: 'rodent', child: Text('Гризун')),
                        DropdownMenuItem(value: 'other', child: Text('Інше')),
                      ],
                      onChanged: isLoading
                          ? null
                          : (value) {
                              if (value == null) return;

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
                        hintText: 'Наприклад: Метис',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _gender,
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
                              if (value == null) return;

                              setState(() {
                                _gender = value;
                              });
                            },
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Зовнішній вигляд',
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
                        hintText: 'Білий з коричневими плямами',
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
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Вага, кг',
                        hintText: 'Наприклад: 8.5',
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
                          return 'Вага має бути реалістичною';
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
                        hintText: 'Пляма біля ока, нашийник, шрам тощо',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _chipNumberController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Номер чіпа',
                        hintText: 'Необовʼязково',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _birthDateController,
                      keyboardType: TextInputType.datetime,
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
                          return 'Дата народження не може бути в майбутньому';
                        }

                        return null;
                      },
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

                    ElevatedButton(
                      onPressed: isLoading ? null : _createPet,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Зберегти'),
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