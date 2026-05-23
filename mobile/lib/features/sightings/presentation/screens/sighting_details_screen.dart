import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_section_card.dart';
import '../../../../shared/widgets/location_preview_card.dart';
import '../../data/models/sighting_model.dart';
import '../cubit/sightings_cubit.dart';
import '../cubit/sightings_state.dart';

/// Екран деталей одного свідчення.
/// Показує інформацію про побачену тварину,
/// місце та час спостереження, а також зв’язок із SOS.
class SightingDetailsScreen extends StatefulWidget {
  final String sightingId;

  const SightingDetailsScreen({
    super.key,
    required this.sightingId,
  });

  @override
  State<SightingDetailsScreen> createState() =>
      _SightingDetailsScreenState();
}

class _SightingDetailsScreenState extends State<SightingDetailsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSighting();
    });
  }

  /// Завантажує актуальні дані свідчення.
  Future<void> _loadSighting() async {
    await context.read<SightingsCubit>().loadSightingById(
          widget.sightingId,
        );
  }

  String _speciesLabel(String species) {
    switch (species) {
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
    return BlocConsumer<SightingsCubit, SightingsState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
              ),
            );

          context.read<SightingsCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        final selectedSighting = state.selectedSighting;

        /// Не показуємо дані іншого свідчення,
        /// якщо користувач перейшов між екранами під час завантаження.
        final sighting = selectedSighting?.id == widget.sightingId
            ? selectedSighting
            : null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Свідчення'),
            actions: [
              IconButton(
                onPressed: state.isLoading ? null : _loadSighting,
                icon: const Icon(Icons.refresh),
                tooltip: 'Оновити',
              ),
            ],
          ),
          body: Builder(
            builder: (context) {
              if (state.isLoading && sighting == null) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (sighting == null) {
                return const _SightingNotFoundState();
              }

              return Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: _loadSighting,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        _SightingHeroCard(
                          sighting: sighting,
                          speciesLabel: sighting.pet == null
                              ? null
                              : _speciesLabel(sighting.pet!.species),
                        ),

                        const SizedBox(height: 12),

                        _SightingNoticeCard(
                          sighting: sighting,
                        ),

                        const SizedBox(height: 12),

                        AppSectionCard(
                          title: 'Інформація про спостереження',
                          icon: Icons.visibility_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  SightingStatusBadge(
                                    status: sighting.status,
                                  ),
                                  ConfidenceBadge(
                                    level: sighting.confidenceLevel,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _InfoRow(
                                label: 'Коли помічено',
                                value: AppFormatters.dateTimeFromIso(
                                  sighting.seenAt,
                                ),
                              ),
                              _InfoRow(
                                label: 'Опис',
                                value: sighting.description,
                                showDivider: false,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        LocationPreviewCard(
                          title: 'Місце спостереження',
                          description: sighting.location.address ??
                              sighting.location.city ??
                              'Місце позначено на карті',
                          latitude: sighting.location.latitude,
                          longitude: sighting.location.longitude,
                          markerIcon: Icons.visibility,
                          markerColor: Colors.orange,
                        ),

                        const SizedBox(height: 12),

                        AppSectionCard(
                          title: 'Пов’язане оголошення',
                          icon: Icons.campaign_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                sighting.pet == null
                                    ? 'Це свідчення додано до активного SOS-оголошення.'
                                    : 'Свідчення стосується пошуку тварини ${sighting.pet!.name}.',
                              ),
                              const SizedBox(height: 12),
                              FilledButton.tonalIcon(
                                onPressed: sighting.lostReportId.isEmpty
                                    ? null
                                    : () {
                                        context.push(
                                          '/lost-reports/${sighting.lostReportId}',
                                        );
                                      },
                                icon: const Icon(Icons.open_in_new),
                                label: const Text(
                                  'Відкрити SOS-оголошення',
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  if (state.isLoading && sighting != null)
                    Positioned.fill(
                      child: Container(
                        color: Theme.of(context)
                            .colorScheme
                            .scrim
                            .withOpacity(0.08),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// Верхній блок свідчення з фото тварини та короткою інформацією.
class _SightingHeroCard extends StatelessWidget {
  final SightingModel sighting;
  final String? speciesLabel;

  const _SightingHeroCard({
    required this.sighting,
    required this.speciesLabel,
  });

  @override
  Widget build(BuildContext context) {
    final pet = sighting.pet;
    final photoUrl = pet?.fullMainPhotoUrl;

    final title = pet == null
        ? 'Свідчення про тварину'
        : 'Помічено: ${pet.name}';

    final subtitle = pet == null
        ? AppFormatters.dateTimeFromIso(sighting.seenAt)
        : pet.breed?.trim().isNotEmpty == true
            ? '$speciesLabel • ${pet.breed} • ${pet.color}'
            : '$speciesLabel • ${pet.color}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 275,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photoUrl == null)
              Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.pets,
                  size: 84,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            else
              Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    child: Icon(
                      Icons.pets,
                      size: 84,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                },
              ),

            Positioned(
              top: 12,
              left: 12,
              child: SightingStatusBadge(
                status: sighting.status,
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black87,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Спостереження: '
                      '${AppFormatters.dateTimeFromIso(sighting.seenAt)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Повідомлення про поточний стан свідчення.
class _SightingNoticeCard extends StatelessWidget {
  final SightingModel sighting;

  const _SightingNoticeCard({
    required this.sighting,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color backgroundColor;
    Color foregroundColor;
    IconData icon;
    String message;

    switch (sighting.status) {
      case 'confirmed':
        backgroundColor = colorScheme.primaryContainer;
        foregroundColor = colorScheme.onPrimaryContainer;
        icon = Icons.verified_outlined;
        message =
            'Свідчення підтверджено та може бути корисним для пошуку тварини.';
        break;
      case 'rejected':
        backgroundColor = colorScheme.surfaceContainerHighest;
        foregroundColor = colorScheme.onSurfaceVariant;
        icon = Icons.block_outlined;
        message =
            'Це свідчення було відхилене та більше не використовується під час пошуку.';
        break;
      case 'active':
      default:
        backgroundColor = colorScheme.tertiaryContainer;
        foregroundColor = colorScheme.onTertiaryContainer;
        icon = Icons.info_outline;
        message =
            'Свідчення передано власнику тварини та враховується в активному пошуку.';
        break;
    }

    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: foregroundColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Рядок інформації у секції.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;

  const _InfoRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 124,
                child: Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
          ),
      ],
    );
  }
}

/// Стан, коли свідчення не знайдено або воно недоступне.
class _SightingNotFoundState extends StatelessWidget {
  const _SightingNotFoundState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.visibility_off_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Свідчення недоступне',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Свідчення могло бути видалено або більше не доступне для перегляду.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}