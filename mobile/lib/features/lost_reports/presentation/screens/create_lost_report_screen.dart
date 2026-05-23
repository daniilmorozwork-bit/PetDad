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
import '../cubit/lost_reports_cubit.dart';
import '../cubit/lost_reports_state.dart';

/// Екран створення SOS для конкретної тварини.
/// Користувач обирає місце на карті або використовує поточну позицію.
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

  final _descriptionController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _rewardController = TextEditingController();
  final _radiusController = TextEditingController();

  DateTime _lastSeenAt =
      DateTime.now().subtract(const Duration(minutes: 5));

  LatLng? _selectedPoint;
  int? _accuracyMeters;

  bool _showValidationErrors = false;
  bool _pointChosenByUser = false;

  @override
  void initState() {
    super.initState();

    final settings = context.read<SettingsCubit>().state;

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
    _descriptionController.dispose();
    _contactPhoneController.dispose();
    _rewardController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  /// Використовує поточну позицію пристрою як місце зникнення.
  /// Автоматичне визначення не перезаписує точку,
  /// яку користувач уже сам обрав на карті.
  Future<void> _fillCurrentCoordinates({
    bool requestedByUser = false,
  }) async {
    final locationCubit = context.read<CurrentLocationCubit>();

    final cachedLocation = requestedByUser
        ? null
        : locationCubit.state.location;

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

  /// Записує координати пристрою у стан форми.
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

  /// Відкриває карту для ручного вибору точки.
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
            title: 'Місце зникнення',
            instructionText:
                'Натисніть на карту в місці, де тварину бачили востаннє.',
          );
        },
      ),
    );

    if (!mounted || selectedPoint == null) {
      return;
    }

    setState(() {
      _selectedPoint = selectedPoint;

      /// Для точки, вибраної вручну, точність GPS не застосовується.
      _accuracyMeters = null;
      _pointChosenByUser = true;
    });
  }

  /// Дозволяє вибрати нормальну дату і час замість ручного ISO-рядка.
  Future<void> _selectLastSeenDateTime() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _lastSeenAt,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now(),
      helpText: 'Коли тварину бачили востаннє?',
      cancelText: 'Скасувати',
      confirmText: 'Далі',
    );

    if (!mounted || selectedDate == null) {
      return;
    }

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_lastSeenAt),
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
              'Час останнього спостереження не може бути в майбутньому',
            ),
          ),
        );
      return;
    }

    setState(() {
      _lastSeenAt = selectedDateTime;
    });
  }

  Future<void> _createLostReport() async {
    setState(() {
      _showValidationErrors = true;
    });

    if (_selectedPoint == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Оберіть місце, де тварину бачили востаннє'),
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

    final reward = _rewardController.text.trim().isEmpty
        ? null
        : double.tryParse(
            _rewardController.text.trim().replaceAll(',', '.'),
          );

    final radius =
        int.tryParse(_radiusController.text.trim()) ?? 3000;

    await context.read<LostReportsCubit>().createLostReport(
          petId: widget.petId,
          latitude: _selectedPoint!.latitude,
          longitude: _selectedPoint!.longitude,
          accuracyMeters: _accuracyMeters,
          lastSeenAt: _lastSeenAt.toUtc().toIso8601String(),
          description: _descriptionController.text.trim(),
          contactPhone: _contactPhoneController.text.trim(),
          rewardAmount: reward,
          searchRadiusMeters: radius,
        );
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
                      'Повідомлення про зникнення',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Вкажіть останнє відоме місце та важливу інформацію, '
                      'яка допоможе іншим людям упізнати тварину.',
                    ),
                    const SizedBox(height: 20),

                    _SectionTitle(
                      icon: Icons.location_on_outlined,
                      title: 'Останнє відоме місце',
                    ),
                    const SizedBox(height: 10),

                    _LocationCard(
                      selectedPoint: _selectedPoint,
                      accuracyMeters: _accuracyMeters,
                      isLoading: locationState.isLoading,
                      automaticLocationEnabled:
                          settings.useCurrentLocation,
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

                    _SectionTitle(
                      icon: Icons.schedule_outlined,
                      title: 'Коли бачили востаннє',
                    ),
                    const SizedBox(height: 10),

                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.calendar_month_outlined),
                        title: const Text('Дата і час'),
                        subtitle: Text(
                          AppFormatters.dateTime(_lastSeenAt),
                        ),
                        trailing: const Icon(Icons.edit_outlined),
                        onTap: isLoading
                            ? null
                            : _selectLastSeenDateTime,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _SectionTitle(
                      icon: Icons.description_outlined,
                      title: 'Опис ситуації',
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _descriptionController,
                      minLines: 4,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Що сталося?',
                        hintText:
                            'Наприклад: зірвалася з повідка біля парку, '
                            'побігла у напрямку магазину...',
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

                    _SectionTitle(
                      icon: Icons.contact_phone_outlined,
                      title: 'Контакти та умови пошуку',
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _contactPhoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Контактний телефон',
                        hintText: 'Необовʼязково',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _rewardController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Винагорода',
                        hintText: 'Необовʼязково',
                        prefixIcon: Icon(Icons.payments_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';

                        if (text.isEmpty) {
                          return null;
                        }

                        final amount = double.tryParse(
                          text.replaceAll(',', '.'),
                        );

                        if (amount == null || amount < 0) {
                          return 'Введіть коректну суму';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _radiusController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Радіус пошуку',
                        helperText: 'Поточне значення: ${AppFormatters.distance(
                          int.tryParse(_radiusController.text) ??
                              settings.defaultSearchRadiusMeters,
                        )}',
                        prefixIcon: const Icon(Icons.radar_outlined),
                        suffixText: 'м',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setState(() {});
                      },
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
                          return 'Радіус має бути від 500 м до 50 км';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 26),

                    FilledButton.icon(
                      onPressed: isLoading ? null : _createLostReport,
                      icon: const Icon(Icons.campaign_outlined),
                      label: Text(
                        isLoading
                            ? 'Публікація...'
                            : 'Опублікувати SOS',
                      ),
                    ),
                    const SizedBox(height: 10),

                    Text(
                      'Після публікації оголошення буде показане на карті '
                      'та стане доступним іншим користувачам.',
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

/// Заголовок групи полів форми.
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

/// Картка вибору місця зникнення.
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
          ? 'Точку вибрано на карті.'
          : 'Поточну позицію визначено з точністю ± $accuracyMeters м.';
    } else if (errorMessage != null) {
      description = errorMessage!;
    } else if (!automaticLocationEnabled) {
      description =
          'Автоматичне визначення позиції вимкнено. '
          'Оберіть місце вручну або використайте свою позицію.';
    } else {
      description = 'Місце ще не вибрано.';
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