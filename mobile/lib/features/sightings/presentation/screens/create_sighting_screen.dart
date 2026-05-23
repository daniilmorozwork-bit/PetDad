import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/screens/location_picker_screen.dart';
import '../../../current_location/data/models/current_location_model.dart';
import '../../../current_location/presentation/cubit/current_location_cubit.dart';
import '../../../current_location/presentation/cubit/current_location_state.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../cubit/sightings_cubit.dart';
import '../cubit/sightings_state.dart';

/// Екран створення свідчення до активного SOS.
/// Користувач повідомляє, де й коли бачив тварину.
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
  final _descriptionController = TextEditingController();

  DateTime _seenAt = DateTime.now().subtract(const Duration(minutes: 1));

  LatLng? _selectedPoint;
  int? _accuracyMeters;

  String _confidenceLevel = 'medium';
  bool _showValidationErrors = false;
  bool _pointChosenByUser = false;

  @override
  void initState() {
    super.initState();

    final settings = context.read<SettingsCubit>().state;

    if (settings.useCurrentLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fillCurrentCoordinates();
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  /// Підставляє поточну позицію користувача у форму.
  /// Автоматичне отримання координат не перезаписує точку,
  /// яку користувач уже обрав на карті вручну.
  Future<void> _fillCurrentCoordinates({
    bool requestedByUser = false,
  }) async {
    final locationCubit = context.read<CurrentLocationCubit>();

    final cachedLocation =
        requestedByUser ? null : locationCubit.state.location;

    final location =
        cachedLocation ?? await locationCubit.loadCurrentLocation();

    if (!mounted || location == null) {
      return;
    }

    if (!requestedByUser && _pointChosenByUser) {
      return;
    }

    _setLocationFromDevice(
      location,
      requestedByUser: requestedByUser,
    );
  }

  /// Записує отриману позицію у стан форми.
  void _setLocationFromDevice(
    CurrentLocationModel location, {
    required bool requestedByUser,
  }) {
    setState(() {
      _selectedPoint = LatLng(
        location.latitude,
        location.longitude,
      );
      _accuracyMeters = location.accuracyMeters;

      if (requestedByUser) {
        _pointChosenByUser = true;
      }
    });
  }

  /// Відкриває карту для вибору місця спостереження.
  Future<void> _selectLocationOnMap() async {
    final cachedLocation =
        context.read<CurrentLocationCubit>().state.location;

    final initialPoint = _selectedPoint ??
        (cachedLocation == null
            ? const LatLng(50.4501, 30.5234)
            : LatLng(
                cachedLocation.latitude,
                cachedLocation.longitude,
              ));

    final selectedPoint = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (context) {
          return LocationPickerScreen(
            initialPoint: initialPoint,
            title: 'Місце спостереження',
            instructionText:
                'Натисніть на карту в місці, де ви бачили тварину.',
          );
        },
      ),
    );

    if (!mounted || selectedPoint == null) {
      return;
    }

    setState(() {
      _selectedPoint = selectedPoint;

      /// Для вручну вибраної точки GPS-точність не використовується.
      _accuracyMeters = null;
      _pointChosenByUser = true;
    });
  }

  /// Відкриває вибір дати й часу спостереження.
  Future<void> _selectSeenDateTime() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _seenAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: 'Коли ви бачили тварину?',
      cancelText: 'Скасувати',
      confirmText: 'Далі',
    );

    if (!mounted || selectedDate == null) {
      return;
    }

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_seenAt),
      helpText: 'Оберіть приблизний час',
      cancelText: 'Скасувати',
      confirmText: 'Підтвердити',
    );

    if (!mounted || selectedTime == null) {
      return;
    }

    final selectedDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (selectedDateTime.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Час спостереження не може бути в майбутньому',
            ),
          ),
        );
      return;
    }

    setState(() {
      _seenAt = selectedDateTime;
    });
  }

  /// Перевіряє форму та створює свідчення.
  Future<void> _createSighting() async {
    setState(() {
      _showValidationErrors = true;
    });

    if (_selectedPoint == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Оберіть місце, де ви бачили тварину'),
          ),
        );
      return;
    }

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
          latitude: _selectedPoint!.latitude,
          longitude: _selectedPoint!.longitude,
          accuracyMeters: _accuracyMeters,
          seenAt: _seenAt.toUtc().toIso8601String(),
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
                      'Ви бачили цю тварину?',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ваше повідомлення допоможе власнику уточнити напрямок пошуку.',
                    ),
                    const SizedBox(height: 20),

                    const _SectionTitle(
                      icon: Icons.location_on_outlined,
                      title: 'Місце спостереження',
                    ),
                    const SizedBox(height: 10),

                    _LocationCard(
                      selectedPoint: _selectedPoint,
                      accuracyMeters: _accuracyMeters,
                      isLoading: locationState.isLoading,
                      automaticLocationEnabled: settings.useCurrentLocation,
                      errorMessage: locationState.errorMessage,
                      onUseCurrentLocation: isLoading
                          ? null
                          : () {
                              _fillCurrentCoordinates(
                                requestedByUser: true,
                              );
                            },
                      onSelectOnMap:
                          isLoading ? null : _selectLocationOnMap,
                    ),

                    const SizedBox(height: 20),

                    const _SectionTitle(
                      icon: Icons.schedule_outlined,
                      title: 'Час спостереження',
                    ),
                    const SizedBox(height: 10),

                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.calendar_month_outlined),
                        title: const Text('Дата і час'),
                        subtitle: Text(
                          AppFormatters.dateTime(_seenAt),
                        ),
                        trailing: const Icon(Icons.edit_outlined),
                        onTap: isLoading ? null : _selectSeenDateTime,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const _SectionTitle(
                      icon: Icons.notes_outlined,
                      title: 'Що ви помітили',
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _descriptionController,
                      minLines: 4,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Опис спостереження',
                        hintText:
                            'Наприклад: схожий собака перебіг дорогу біля '
                            'магазину й побіг у бік парку...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';

                        if (text.isEmpty) {
                          return 'Опис є обовʼязковим';
                        }

                        if (text.length < 10) {
                          return 'Додайте більше інформації';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    const _SectionTitle(
                      icon: Icons.verified_outlined,
                      title: 'Наскільки ви впевнені',
                    ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      initialValue: _confidenceLevel,
                      decoration: const InputDecoration(
                        labelText: 'Рівень впевненості',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'low',
                          child: Text('Низький — можливо, схожа тварина'),
                        ),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Text('Середній — дуже схожа тварина'),
                        ),
                        DropdownMenuItem(
                          value: 'high',
                          child: Text('Високий — майже впевнений/впевнена'),
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

                    const SizedBox(height: 26),

                    FilledButton.icon(
                      onPressed: isLoading ? null : _createSighting,
                      icon: const Icon(Icons.send_outlined),
                      label: Text(
                        isLoading
                            ? 'Надсилання...'
                            : 'Надіслати свідчення',
                      ),
                    ),
                    const SizedBox(height: 10),

                    Text(
                      'Свідчення буде передано власнику та показано на карті подій.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
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

/// Заголовок групи полів.
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Картка вибору місця спостереження.
class _LocationCard extends StatelessWidget {
  final LatLng? selectedPoint;
  final int? accuracyMeters;
  final bool isLoading;
  final bool automaticLocationEnabled;
  final String? errorMessage;
  final VoidCallback? onUseCurrentLocation;
  final VoidCallback? onSelectOnMap;

  const _LocationCard({
    required this.selectedPoint,
    required this.accuracyMeters,
    required this.isLoading,
    required this.automaticLocationEnabled,
    required this.errorMessage,
    required this.onUseCurrentLocation,
    required this.onSelectOnMap,
  });

  @override
  Widget build(BuildContext context) {
    String description;

    if (isLoading) {
      description = 'Визначення поточної позиції...';
    } else if (selectedPoint != null) {
      description = accuracyMeters == null
          ? 'Точку спостереження вибрано на карті.'
          : 'Поточну позицію визначено з точністю ± $accuracyMeters м.';
    } else if (errorMessage != null) {
      description = errorMessage!;
    } else if (!automaticLocationEnabled) {
      description =
          'Автоматичне визначення позиції вимкнено. '
          'Оберіть місце вручну або використайте свою позицію.';
    } else {
      description = 'Місце спостереження ще не вибрано.';
    }

    return Card(
      color: selectedPoint == null
          ? Theme.of(context).colorScheme.surfaceContainerLow
          : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.28),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selectedPoint == null
                      ? Icons.location_off_outlined
                      : Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(description),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onUseCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: const Text('Моя поточна позиція'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: onSelectOnMap,
              icon: const Icon(Icons.map_outlined),
              label: const Text('Вибрати на карті'),
            ),
          ],
        ),
      ),
    );
  }
}