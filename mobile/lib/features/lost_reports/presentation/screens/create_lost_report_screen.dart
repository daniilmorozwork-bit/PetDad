import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubit/lost_reports_cubit.dart';
import '../cubit/lost_reports_state.dart';

/// Екран створення SOS для конкретної тварини.
class CreateLostReportScreen extends StatefulWidget {
  final String petId;

  const CreateLostReportScreen({
    super.key,
    required this.petId,
  });

  @override
  State<CreateLostReportScreen> createState() => _CreateLostReportScreenState();
}

class _CreateLostReportScreenState extends State<CreateLostReportScreen> {
  final _formKey = GlobalKey<FormState>();

  final _latitudeController = TextEditingController(text: '50.4501');
  final _longitudeController = TextEditingController(text: '30.5234');
  final _accuracyController = TextEditingController(text: '25');
  final _lastSeenAtController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _rewardController = TextEditingController();
  final _radiusController = TextEditingController(text: '3000');

  bool _showValidationErrors = false;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now().subtract(const Duration(minutes: 5)).toUtc();
    _lastSeenAtController.text = now.toIso8601String();
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _accuracyController.dispose();
    _lastSeenAtController.dispose();
    _descriptionController.dispose();
    _contactPhoneController.dispose();
    _rewardController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _createLostReport() async {
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

    final latitude = double.parse(_latitudeController.text.trim());
    final longitude = double.parse(_longitudeController.text.trim());
    final accuracy = int.tryParse(_accuracyController.text.trim());
    final reward = _rewardController.text.trim().isEmpty
        ? null
        : double.tryParse(_rewardController.text.trim());
    final radius = int.tryParse(_radiusController.text.trim()) ?? 3000;

    await context.read<LostReportsCubit>().createLostReport(
          petId: widget.petId,
          latitude: latitude,
          longitude: longitude,
          accuracyMeters: accuracy,
          lastSeenAt: _lastSeenAtController.text.trim(),
          description: _descriptionController.text.trim(),
          contactPhone: _contactPhoneController.text.trim(),
          rewardAmount: reward,
          searchRadiusMeters: radius,
        );
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LostReportsCubit, LostReportsState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          final reportId = state.selectedReport?.id;

          context.read<LostReportsCubit>().clearMessages();

          if (reportId != null) {
            context.pushReplacement('/lost-reports/$reportId');
          } else {
            context.pushReplacement('/lost-reports');
          }
        }

        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );

          context.read<LostReportsCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        final isLoading = state.isLoading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Створити SOS'),
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
                      'Дані про зникнення',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Для MVP координати вводяться вручну. Пізніше замінимо це вибором точки на карті.',
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _latitudeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Широта',
                        hintText: '50.4501',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        return _validateCoordinate(
                          value: value,
                          label: 'Широта',
                          min: -90,
                          max: 90,
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _longitudeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Довгота',
                        hintText: '30.5234',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        return _validateCoordinate(
                          value: value,
                          label: 'Довгота',
                          min: -180,
                          max: 180,
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _accuracyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Точність, м',
                        hintText: '25',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _lastSeenAtController,
                      decoration: const InputDecoration(
                        labelText: 'Час останнього спостереження',
                        hintText: '2026-05-17T15:30:00.000Z',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';

                        if (text.isEmpty) {
                          return 'Час останнього спостереження є обовʼязковим';
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
                        labelText: 'Опис ситуації',
                        hintText:
                            'Де бачили тварину, куди могла побігти, які прикмети важливі',
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

                    TextFormField(
                      controller: _contactPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Контактний телефон',
                        hintText: '+380501112233',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _rewardController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Винагорода',
                        hintText: 'Необовʼязково',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _radiusController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Радіус пошуку, м',
                        hintText: '3000',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';

                        if (text.isEmpty) {
                          return 'Радіус пошуку є обовʼязковим';
                        }

                        final number = int.tryParse(text);

                        if (number == null) {
                          return 'Радіус має бути числом';
                        }

                        if (number < 500 || number > 50000) {
                          return 'Радіус має бути від 500 до 50000 м';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    FilledButton.icon(
                      onPressed: isLoading ? null : _createLostReport,
                      icon: const Icon(Icons.campaign_outlined),
                      label: isLoading
                          ? const Text('Створення...')
                          : const Text('Опублікувати SOS'),
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