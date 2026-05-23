import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_section_card.dart';
import '../../../../shared/widgets/location_preview_card.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../sightings/presentation/cubit/sightings_cubit.dart';
import '../../../sightings/presentation/cubit/sightings_state.dart';
import '../../../sightings/presentation/widgets/sighting_card.dart';
import '../../data/models/lost_report_model.dart';
import '../cubit/lost_reports_cubit.dart';
import '../cubit/lost_reports_state.dart';

/// Екран деталей SOS-оголошення.
/// Показує інформацію про зниклу тварину, місце пошуку,
/// доступні дії та отримані свідчення.
class LostReportDetailsScreen extends StatefulWidget {
  final String reportId;

  const LostReportDetailsScreen({
    super.key,
    required this.reportId,
  });

  @override
  State<LostReportDetailsScreen> createState() =>
      _LostReportDetailsScreenState();
}

class _LostReportDetailsScreenState extends State<LostReportDetailsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshReport();
    });
  }

  /// Оновлює дані SOS та список свідчень.
  Future<void> _refreshReport() async {
    await Future.wait([
      context.read<LostReportsCubit>().loadLostReportById(widget.reportId),
      context
          .read<SightingsCubit>()
          .loadSightingsByLostReport(widget.reportId),
    ]);
  }

  /// Закриває активне SOS-оголошення.
  Future<void> _closeReport() async {
    String closeReason = 'pet_found';
    final commentController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Закрити SOS-оголошення?'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Після закриття оголошення перестане відображатися серед активних подій пошуку.',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: closeReason,
                    decoration: const InputDecoration(
                      labelText: 'Причина закриття',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'pet_found',
                        child: Text('Тварину знайдено'),
                      ),
                      DropdownMenuItem(
                        value: 'created_by_mistake',
                        child: Text('Створено помилково'),
                      ),
                      DropdownMenuItem(
                        value: 'duplicate',
                        child: Text('Дублікат оголошення'),
                      ),
                      DropdownMenuItem(
                        value: 'other',
                        child: Text('Інша причина'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setDialogState(() {
                        closeReason = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Коментар',
                      hintText: 'Наприклад: тварину знайшли біля будинку',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Скасувати'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Закрити SOS'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      commentController.dispose();
      return;
    }

    final closeComment = commentController.text.trim();
    commentController.dispose();

    await context.read<LostReportsCubit>().closeLostReport(
          reportId: widget.reportId,
          closeReason: closeReason,
          closeComment: closeComment,
        );
  }

  /// Копіює контактний телефон із SOS.
  Future<void> _copyPhone(String phone) async {
    await Clipboard.setData(
      ClipboardData(text: phone),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Номер телефону скопійовано'),
        ),
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

  String _closeReasonLabel(String? reason) {
    switch (reason) {
      case 'pet_found':
        return 'Тварину знайдено';
      case 'created_by_mistake':
        return 'Оголошення створено помилково';
      case 'duplicate':
        return 'Дублікат оголошення';
      case 'other':
        return 'Інша причина';
      default:
        return 'Не вказано';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;

    return BlocConsumer<LostReportsCubit, LostReportsState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
              ),
            );

          context.read<LostReportsCubit>().clearMessages();
        }

        if (state.successMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
              ),
            );

          context.read<LostReportsCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        final selectedReport = state.selectedReport;

        /// Не показуємо попереднє SOS, поки завантажується інше.
        final report = selectedReport?.id == widget.reportId
            ? selectedReport
            : null;

        final isOwner = report != null &&
            authState is AuthAuthenticated &&
            authState.user.id == report.ownerId;

        return Scaffold(
          appBar: AppBar(
            title: const Text('SOS-оголошення'),
            actions: [
              IconButton(
                onPressed: state.isLoading ? null : _refreshReport,
                icon: const Icon(Icons.refresh),
                tooltip: 'Оновити',
              ),
            ],
          ),
          body: Builder(
            builder: (context) {
              if (state.isLoading && report == null) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (report == null) {
                return const _ReportNotFoundState();
              }

              return Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: _refreshReport,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        _SosHeroCard(
                          report: report,
                          speciesLabel: _speciesLabel(report.pet.species),
                        ),

                        const SizedBox(height: 12),

                        _SearchNoticeCard(
                          report: report,
                          isOwner: isOwner,
                        ),

                        const SizedBox(height: 12),

                        AppSectionCard(
                          title: 'Інформація про пошук',
                          icon: Icons.search_outlined,
                          child: Column(
                            children: [
                              _InfoRow(
                                label: 'Опис',
                                value: report.description,
                              ),
                              _InfoRow(
                                label: 'Зникнення',
                                value: AppFormatters.dateTimeFromIso(
                                  report.lastSeenAt,
                                ),
                              ),
                              _InfoRow(
                                label: 'Радіус',
                                value: AppFormatters.distance(
                                  report.searchRadiusMeters,
                                ),
                              ),
                              _InfoRow(
                                label: 'Винагорода',
                                value: AppFormatters.amount(
                                  report.rewardAmount,
                                ),
                                showDivider: false,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        LocationPreviewCard(
                          title: 'Місце останнього спостереження',
                          description: report.lastSeenLocation.address ??
                              report.lastSeenLocation.city ??
                              'Місце позначено на карті',
                          latitude: report.lastSeenLocation.latitude,
                          longitude: report.lastSeenLocation.longitude,
                          markerIcon: Icons.campaign,
                          markerColor: Colors.red,
                        ),

                        if (report.status == 'active') ...[
                          const SizedBox(height: 12),
                          _ActionsCard(
                            report: report,
                            isOwner: isOwner,
                            onCloseReport: _closeReport,
                            onAddSighting: () {
                              context.push(
                                '/lost-reports/${report.id}/sightings/create',
                              );
                            },
                            onCopyPhone: report.contactPhone == null
                                ? null
                                : () {
                                    _copyPhone(report.contactPhone!);
                                  },
                          ),
                        ],

                        if (report.status != 'active') ...[
                          const SizedBox(height: 12),
                          AppSectionCard(
                            title: 'Результат пошуку',
                            icon: Icons.check_circle_outline,
                            child: Column(
                              children: [
                                _InfoRow(
                                  label: 'Закрито',
                                  value: AppFormatters.dateTimeFromIso(
                                    report.closedAt,
                                  ),
                                ),
                                _InfoRow(
                                  label: 'Причина',
                                  value: _closeReasonLabel(
                                    report.closeReason,
                                  ),
                                ),
                                _InfoRow(
                                  label: 'Коментар',
                                  value: report.closeComment?.trim().isNotEmpty ==
                                          true
                                      ? report.closeComment!
                                      : 'Не вказано',
                                  showDivider: false,
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        BlocBuilder<SightingsCubit, SightingsState>(
                          builder: (context, sightingsState) {
                            return AppSectionCard(
                              title: 'Свідчення',
                              icon: Icons.visibility_outlined,
                              trailing: IconButton(
                                onPressed: sightingsState.isLoading
                                    ? null
                                    : () {
                                        context
                                            .read<SightingsCubit>()
                                            .loadSightingsByLostReport(
                                              widget.reportId,
                                            );
                                      },
                                icon: const Icon(Icons.refresh),
                                tooltip: 'Оновити свідчення',
                              ),
                              child: _SightingsSection(
                                state: sightingsState,
                                onOpenSighting: (sightingId) {
                                  context.push('/sightings/$sightingId');
                                },
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  if (state.isLoading && report != null)
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

/// Верхній блок SOS із фото тварини й основною інформацією.
class _SosHeroCard extends StatelessWidget {
  final LostReportModel report;
  final String speciesLabel;

  const _SosHeroCard({
    required this.report,
    required this.speciesLabel,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = report.pet.fullMainPhotoUrl;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 285,
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
              child: ReportStatusBadge(
                status: report.status,
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 54, 16, 16),
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
                      report.status == 'active'
                          ? 'Розшукується: ${report.pet.name}'
                          : report.pet.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.pet.breed?.trim().isNotEmpty == true
                          ? '$speciesLabel • ${report.pet.breed} • ${report.pet.color}'
                          : '$speciesLabel • ${report.pet.color}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Зникнення: '
                      '${AppFormatters.dateTimeFromIso(report.lastSeenAt)}',
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

/// Акцентне повідомлення про поточний стан пошуку.
class _SearchNoticeCard extends StatelessWidget {
  final LostReportModel report;
  final bool isOwner;

  const _SearchNoticeCard({
    required this.report,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isActive = report.status == 'active';

    final backgroundColor = isActive && !isOwner
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;

    final foregroundColor = isActive && !isOwner
        ? colorScheme.onErrorContainer
        : colorScheme.onPrimaryContainer;

    String message;

    if (!isActive) {
      message = 'Пошук завершено. Оголошення більше не відображається '
          'серед активних SOS-подій.';
    } else if (isOwner) {
      message = 'Пошук активний. Нові свідчення користувачів '
          'відображатимуться нижче та у повідомленнях.';
    } else {
      message = 'Цю тварину розшукують. Якщо ви її бачили, '
          'надішліть свідчення із місцем і часом спостереження.';
    }

    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isActive ? Icons.campaign_outlined : Icons.check_circle_outline,
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

/// Доступні дії для активного SOS.
class _ActionsCard extends StatelessWidget {
  final LostReportModel report;
  final bool isOwner;
  final VoidCallback onCloseReport;
  final VoidCallback onAddSighting;
  final VoidCallback? onCopyPhone;

  const _ActionsCard({
    required this.report,
    required this.isOwner,
    required this.onCloseReport,
    required this.onAddSighting,
    required this.onCopyPhone,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: isOwner ? 'Керування пошуком' : 'Допомогти пошуку',
      icon: isOwner
          ? Icons.manage_search_outlined
          : Icons.volunteer_activism_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isOwner) ...[
            const Text(
              'Коли тварину буде знайдено або оголошення стане неактуальним, '
              'закрийте SOS-пошук.',
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: onCloseReport,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Закрити SOS-оголошення'),
            ),
          ] else ...[
            FilledButton.icon(
              onPressed: onAddSighting,
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Я бачив цю тварину'),
            ),
            if (report.contactPhone?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onCopyPhone,
                icon: const Icon(Icons.phone_outlined),
                label: Text('Контакт: ${report.contactPhone}'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Вміст секції свідчень.
class _SightingsSection extends StatelessWidget {
  final SightingsState state;
  final ValueChanged<String> onOpenSighting;

  const _SightingsSection({
    required this.state,
    required this.onOpenSighting,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.sightings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(18),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state.sightings.isEmpty) {
      return const Column(
        children: [
          Icon(
            Icons.visibility_off_outlined,
            size: 42,
          ),
          SizedBox(height: 8),
          Text(
            'Свідчень поки немає',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Інформація від інших користувачів з’явиться у цьому блоці.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Отримано свідчень: ${state.sightings.length}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        ...state.sightings.map(
          (sighting) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SightingCard(
              sighting: sighting,
              onTap: () {
                onOpenSighting(sighting.id);
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Рядок інформації у картці.
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
                width: 112,
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

/// Стан, коли SOS недоступне.
class _ReportNotFoundState extends StatelessWidget {
  const _ReportNotFoundState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'SOS-оголошення недоступне',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Оголошення могло бути видалено або більше не доступне для перегляду.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}