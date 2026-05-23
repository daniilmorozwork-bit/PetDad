import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubit/sightings_cubit.dart';
import '../cubit/sightings_state.dart';
import '../../../current_location/data/models/current_location_model.dart';
import '../../../current_location/presentation/cubit/current_location_cubit.dart';
import '../../../current_location/presentation/cubit/current_location_state.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';


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

  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _accuracyController = TextEditingController();
  final _seenAtController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _confidenceLevel = 'medium';
  bool _showValidationErrors = false;

 @override
void initState() {
  super.initState();

  final settings = context.read<SettingsCubit>().state;

  _seenAtController.text = DateTime.now()
      .subtract(const Duration(minutes: 1))
      .toUtc()
      .toIso8601String();

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
    _seenAtController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
    
    /// Записує поточну позицію у поля свідчення.
  void _setCoordinates(CurrentLocationModel location) {
    _latitudeController.text = location.latitude.toStringAsFixed(6);
    _longitudeController.text = location.longitude.toStringAsFixed(6);
    _accuracyController.text = location.accuracyMeters.toString();
  }

  /// Автоматично підставляє поточну позицію.
  /// Поля можна змінити, якщо свідчення стосується іншої точки.
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
    final locationState = context.watch<CurrentLocationCubit>().state;
    final settings = context.watch<SettingsCubit>().state;
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
                   Text(
                      settings.useCurrentLocation
                          ? 'Координати автоматично заповнюються вашою поточною позицією. За потреби можна вказати інше місце вручну.'
                          : 'Автоматичне визначення позиції вимкнено. Координати можна ввести вручну або отримати кнопкою нижче.',
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
                                            ? 'Поточну позицію підставлено у форму.'
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
                              label: const Text('Оновити мою позицію'),
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
                        labelText: 'Широта місця спостереження',
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
                        labelText: 'Довгота місця спостереження',
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
                        labelText: 'Точність координат, м',
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