import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../sightings/presentation/cubit/sightings_cubit.dart';
import '../../../sightings/presentation/cubit/sightings_state.dart';
import '../../../sightings/presentation/widgets/sighting_card.dart';
import '../cubit/lost_reports_cubit.dart';
import '../cubit/lost_reports_state.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/location_preview_card.dart';
import '../../../../shared/widgets/app_badges.dart';

/// Екран деталей SOS.
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
      context.read<LostReportsCubit>().loadLostReportById(widget.reportId);
      context.read<SightingsCubit>().loadSightingsByLostReport(widget.reportId);
    });
  }

  Future<void> _closeReport() async {
    String closeReason = 'pet_found';
    final commentController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Закрити SOS?'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                        child: Text('Дублікат'),
                      ),
                      DropdownMenuItem(
                        value: 'other',
                        child: Text('Інше'),
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
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Скасувати'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Закрити'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      commentController.dispose();
      return;
    }

    await context.read<LostReportsCubit>().closeLostReport(
          reportId: widget.reportId,
          closeReason: closeReason,
          closeComment: commentController.text,
        );

    commentController.dispose();
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
              SnackBar(content: Text(state.errorMessage!)),
            );

          context.read<LostReportsCubit>().clearMessages();
        }

        if (state.successMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(state.successMessage!)),
            );

          context.read<LostReportsCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        final report = state.selectedReport;

        final isOwner = report != null &&
            authState is AuthAuthenticated &&
            authState.user.id == report.ownerId;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Деталі SOS'),
            actions: [
              if (report?.status == 'active' && isOwner)
                IconButton(
                  onPressed: state.isLoading ? null : _closeReport,
                  icon: const Icon(Icons.check_circle_outline),
                  tooltip: 'Закрити SOS',
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
                return const Center(
                  child: Text('SOS не знайдено'),
                );
              }

              final photoUrl = report.pet.fullMainPhotoUrl;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 220,
                      child: photoUrl == null
                          ? Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              child: const Center(
                                child: Icon(Icons.pets, size: 72),
                              ),
                            )
                          : Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  child: const Center(
                                    child: Icon(Icons.pets, size: 72),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Зникла тварина: ${report.pet.name}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  ReportStatusBadge(
                    status: report.status,
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    label: 'Опис',
                    value: report.description,
                  ),
                  _InfoRow(
                    label: 'Зникнення',
                    value: AppFormatters.dateTimeFromIso(report.lastSeenAt),
                  ),
                  _InfoRow(
                    label: 'Радіус пошуку',
                    value: AppFormatters.distance(report.searchRadiusMeters),
                  ),
                  _InfoRow(
                    label: 'Телефон',
                    value: report.contactPhone ?? 'Не вказано',
                  ),
                  _InfoRow(
                    label: 'Винагорода',
                    value: AppFormatters.amount(report.rewardAmount),
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
                  if (report.closedAt != null) ...[
                    const Divider(height: 32),
                   _InfoRow(
                      label: 'Закрито',
                      value: AppFormatters.dateTimeFromIso(report.closedAt),
                    ),
                    _InfoRow(
                      label: 'Причина',
                      value: _closeReasonLabel(report.closeReason),
                    ),
                    _InfoRow(
                      label: 'Коментар',
                      value: report.closeComment ?? 'Не вказано',
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (report.status == 'active' && isOwner)
                    FilledButton.icon(
                      onPressed: state.isLoading ? null : _closeReport,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Закрити SOS'),
                    ),
                  if (report.status == 'active' && !isOwner)
                    FilledButton.icon(
                      onPressed: () {
                        context.push(
                          '/lost-reports/${report.id}/sightings/create',
                        );
                      },
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Я бачив цю тварину'),
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'Свідчення',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  BlocBuilder<SightingsCubit, SightingsState>(
                    builder: (context, sightingsState) {
                      if (sightingsState.isLoading &&
                          sightingsState.sightings.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (sightingsState.sightings.isEmpty) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Свідчень поки немає.',
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: sightingsState.sightings.map((sighting) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: SightingCard(
                              sighting: sighting,
                              onTap: () {
                                context.push('/sightings/${sighting.id}');
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
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

/// Рядок даних SOS.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}