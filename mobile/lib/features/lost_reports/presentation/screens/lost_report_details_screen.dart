import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/lost_reports_cubit.dart';
import '../cubit/lost_reports_state.dart';

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
                    value: closeReason,
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
                      if (value == null) return;

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

    if (confirmed != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    await context.read<LostReportsCubit>().closeLostReport(
          reportId: widget.reportId,
          closeReason: closeReason,
          closeComment: commentController.text,
        );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Активне';
      case 'closed':
        return 'Закрите';
      case 'cancelled':
        return 'Скасоване';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
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

        return Scaffold(
          appBar: AppBar(
            title: const Text('Деталі SOS'),
            actions: [
              if (report?.status == 'active')
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

                  Chip(
                    label: Text(_statusLabel(report.status)),
                    backgroundColor: report.status == 'active'
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                  ),
                  const SizedBox(height: 16),

                  _InfoRow(label: 'Опис', value: report.description),
                  _InfoRow(
                    label: 'Останній раз бачили',
                    value: report.lastSeenAt,
                  ),
                  _InfoRow(
                    label: 'Координати',
                    value:
                        '${report.lastSeenLocation.latitude}, ${report.lastSeenLocation.longitude}',
                  ),
                  _InfoRow(
                    label: 'Радіус пошуку',
                    value: '${report.searchRadiusMeters} м',
                  ),
                  _InfoRow(
                    label: 'Телефон',
                    value: report.contactPhone ?? 'Не вказано',
                  ),
                  _InfoRow(
                    label: 'Винагорода',
                    value: report.rewardAmount == null
                        ? 'Не вказано'
                        : '${report.rewardAmount}',
                  ),

                  if (report.closedAt != null) ...[
                    const Divider(height: 32),
                    _InfoRow(
                      label: 'Закрито',
                      value: report.closedAt!,
                    ),
                    _InfoRow(
                      label: 'Причина',
                      value: report.closeReason ?? 'Не вказано',
                    ),
                    _InfoRow(
                      label: 'Коментар',
                      value: report.closeComment ?? 'Не вказано',
                    ),
                  ],

                  const SizedBox(height: 24),

                  if (report.status == 'active')
                    FilledButton.icon(
                      onPressed: state.isLoading ? null : _closeReport,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Закрити SOS'),
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

/// Рядок даних.
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