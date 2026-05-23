import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubit/sightings_cubit.dart';
import '../cubit/sightings_state.dart';

/// Екран створення свідчення до активного SOS.
class CreateSightingScreen extends StatefulWidget {
  final String lostReportId;

  const CreateSightingScreen({
    super.key,
    required this.lostReportId,
  });

  @override
  State<CreateSightingScreen> createState() => _CreateSightingScreenState();
}

class _CreateSightingScreenState extends State<CreateSightingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _latitudeController = TextEditingController(text: '50.451');
  final _longitudeController = TextEditingController(text: '30.525');
  final _accuracyController = TextEditingController(text: '20');
  final _seenAtController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _confidenceLevel = 'medium';
  bool _showValidationErrors = false;

  @override
  void initState() {
    super.initState();

    _seenAtController.text = DateTime.now().toUtc().toIso8601String();
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _accuracyController.dispose();
    _seenAtController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateCoordinate({
    required String? value,
    required String label,
    required double min,
    required double max,
  }) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return '$label є обовʼязковою';
    }

    final number = double.tryParse(text);

    if (number == null) {
      return '$label має бути числом';
    }

    if (number < min || number > max) {
      return '$label має бути в межах від $min до $max';
    }

    return null;
  }

  Future<void> _createSighting() async {
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

    await context.read<SightingsCubit>().createSighting(
          lostReportId: widget.lostReportId,
          latitude: double.parse(_latitudeController.text.trim()),
          longitude: double.parse(_longitudeController.text.trim()),
          accuracyMeters: int.tryParse(_accuracyController.text.trim()),
          seenAt: _seenAtController.text.trim(),
          description: _descriptionController.text.trim(),
          confidenceLevel: _confidenceLevel,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SightingsCubit, SightingsState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          final sightingId = state.selectedSighting?.id;

          context.read<SightingsCubit>().clearMessages();

          if (sightingId != null) {
            context.pushReplacement('/sightings/$sightingId');
          } else {
            context.pop();
          }
        }

        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );

          context.read<SightingsCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        final isLoading = state.isLoading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Додати свідчення'),
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
                      'Повідомте, де бачили тварину',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Для поточної версії координати вводяться вручну. Пізніше це буде вибір точки на карті.',
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _latitudeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Широта',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => _validateCoordinate(
                        value: value,
                        label: 'Широта',
                        min: -90,
                        max: 90,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _longitudeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Довгота',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => _validateCoordinate(
                        value: value,
                        label: 'Довгота',
                        min: -180,
                        max: 180,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _accuracyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Точність, м',
                        hintText: 'Необовʼязково',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _seenAtController,
                      decoration: const InputDecoration(
                        labelText: 'Час спостереження',
                        hintText: 'ISO datetime',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';

                        if (text.isEmpty) {
                          return 'Час спостереження є обовʼязковим';
                        }

                        final date = DateTime.tryParse(text);

                        if (date == null) {
                          return 'Дата має бути у форматі ISO';
                        }

                        if (date.isAfter(DateTime.now())) {
                          return 'Дата не може бути в майбутньому';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 4,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Опис',
                        hintText:
                            'Де саме бачили тварину та в якому напрямку вона рухалася',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';

                        if (text.isEmpty) {
                          return 'Опис є обовʼязковим';
                        }

                        if (text.length < 10) {
                          return 'Опис має бути детальнішим';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _confidenceLevel,
                      decoration: const InputDecoration(
                        labelText: 'Рівень впевненості',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'low',
                          child: Text('Низький'),
                        ),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Text('Середній'),
                        ),
                        DropdownMenuItem(
                          value: 'high',
                          child: Text('Високий'),
                        ),
                      ],
                      onChanged: isLoading
                          ? null
                          : (value) {
                              if (value == null) {
                                return;
                              }

                              setState(() {
                                _confidenceLevel = value;
                              });
                            },
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: isLoading ? null : _createSighting,
                      icon: const Icon(Icons.visibility_outlined),
                      label: Text(
                        isLoading ? 'Надсилання...' : 'Надіслати свідчення',
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