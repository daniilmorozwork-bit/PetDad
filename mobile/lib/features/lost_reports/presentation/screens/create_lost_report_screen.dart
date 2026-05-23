import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubit/lost_reports_cubit.dart';
import '../cubit/lost_reports_state.dart';
import '../../../current_location/data/models/current_location_model.dart';
import '../../../current_location/presentation/cubit/current_location_cubit.dart';
import '../../../current_location/presentation/cubit/current_location_state.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';

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

  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _accuracyController = TextEditingController();
  final _lastSeenAtController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _rewardController = TextEditingController();
  final _radiusController = TextEditingController();

  bool _showValidationErrors = false;

 @override
void initState() {
  super.initState();

  final settings = context.read<SettingsCubit>().state;

  final now = DateTime.now().subtract(const Duration(minutes: 5)).toUtc();
  _lastSeenAtController.text = now.toIso8601String();
  _radiusController.text =
      settings.defaultSearchRadiusMeters.toString();

  if (settings.useCurrentLocation) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fillCurrentCoordinates();
    });
  }
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

  /// Записує отриману геолокацію у поля форми.
  /// Поля залишаються редагованими, бо місце зникнення
  /// може відрізнятися від поточної позиції користувача.
  void _setCoordinates(CurrentLocationModel location) {
    _latitudeController.text = location.latitude.toStringAsFixed(6);
    _longitudeController.text = location.longitude.toStringAsFixed(6);
    _accuracyController.text = location.accuracyMeters.toString();
  }

  /// Заповнює поля поточною позицією пристрою.
  /// Якщо координати вже отримані раніше, використовуємо їх повторно.
  Future<void> _fillCurrentCoordinates({
    bool forceRefresh = false,
  }) async {
    final locationCubit = context.read<CurrentLocationCubit>();

    final cachedLocation =
        forceRefresh ? null : locationCubit.state.location;

    final location =
        cachedLocation ?? await locationCubit.loadCurrentLocation();

    if (!mounted || location == null) {
      return;
    }

    setState(() {
      _setCoordinates(location);
    });
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
    final locationState = context.watch<CurrentLocationCubit>().state;
    final settings = context.watch<SettingsCubit>().state;

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
                   Text(
                      settings.useCurrentLocation
                          ? 'Координати місця зникнення автоматично заповнюються вашою поточною позицією. За потреби їх можна змінити вручну.'
                          : 'Автоматичне визначення позиції вимкнено. Координати можна ввести вручну або отримати натисканням кнопки нижче.',
                    ),
                    const SizedBox(height: 16),

                    Card(
                      color: locationState.status == CurrentLocationStatus.error
                          ? Colors.orange.shade50
                          : Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  locationState.status == CurrentLocationStatus.error
                                      ? Icons.location_off_outlined
                                      : Icons.my_location,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    locationState.isLoading
                                        ? 'Визначення поточної позиції...'
                                        : locationState.location != null
                                            ? 'Координати підставлено з поточної позиції.'
                                            : locationState.errorMessage ??
                                                'Натисніть кнопку, щоб визначити позицію.',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: locationState.isLoading
                                  ? null
                                  : () {
                                      _fillCurrentCoordinates(forceRefresh: true);
                                    },
                              icon: const Icon(Icons.my_location),
                              label: const Text('Використати мою позицію'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _latitudeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Широта місця зникнення',
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
                        labelText: 'Довгота місця зникнення',
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
                        labelText: 'Точність координат, м',
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