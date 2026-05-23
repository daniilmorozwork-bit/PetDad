import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_section_scaffold.dart';
import '../cubit/lost_reports_cubit.dart';
import '../cubit/lost_reports_state.dart';
import '../widgets/lost_report_card.dart';

/// Екран SOS-оголошень.
/// Дозволяє переглядати активні та завершені пошуки.
class LostReportsScreen extends StatefulWidget {
  const LostReportsScreen({super.key});

  @override
  State<LostReportsScreen> createState() => _LostReportsScreenState();
}

class _LostReportsScreenState extends State<LostReportsScreen> {
  String _selectedStatus = 'active';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReports();
    });
  }

  Future<void> _loadReports() async {
    await context.read<LostReportsCubit>().loadLostReports(
          status: _selectedStatus,
        );
  }

  Future<void> _changeStatus(String status) async {
    if (_selectedStatus == status) {
      return;
    }

    setState(() {
      _selectedStatus = status;
    });

    await _loadReports();
  }

  @override
  Widget build(BuildContext context) {
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
        final isActiveView = _selectedStatus == 'active';

        return AppSectionScaffold(
          title: 'SOS-пошук',
          currentRoute: '/lost-reports',
          actions: [
            IconButton(
              onPressed: state.isLoading ? null : _loadReports,
              icon: const Icon(Icons.refresh),
              tooltip: 'Оновити',
            ),
          ],
          body: RefreshIndicator(
            onRefresh: _loadReports,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _ReportsSummaryCard(
                  reportCount: state.reports.length,
                  isActiveView: isActiveView,
                ),

                const SizedBox(height: 16),

                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'active',
                      icon: Icon(Icons.campaign_outlined),
                      label: Text('Активні'),
                    ),
                    ButtonSegment<String>(
                      value: 'closed',
                      icon: Icon(Icons.check_circle_outline),
                      label: Text('Завершені'),
                    ),
                  ],
                  selected: {_selectedStatus},
                  onSelectionChanged: state.isLoading
                      ? null
                      : (selected) {
                          _changeStatus(selected.first);
                        },
                ),

                const SizedBox(height: 18),

                if (state.isLoading && state.reports.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 52),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (state.reports.isEmpty)
                  AppEmptyState(
                    icon: isActiveView
                        ? Icons.campaign_outlined
                        : Icons.check_circle_outline,
                    title: isActiveView
                        ? 'Активних SOS немає'
                        : 'Завершених пошуків немає',
                    message: isActiveView
                        ? 'SOS створюється з профілю тварини, якщо вона зникла.'
                        : 'Після закриття SOS-оголошення з’являться в цьому списку.',
                    action: isActiveView
                        ? OutlinedButton.icon(
                            onPressed: () {
                              context.push('/pets');
                            },
                            icon: const Icon(Icons.pets_outlined),
                            label: const Text('Перейти до моїх тварин'),
                          )
                        : null,
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isActiveView
                              ? 'Активні оголошення'
                              : 'Завершені оголошення',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${state.reports.length}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  ...state.reports.map(
                    (report) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: LostReportCard(
                        report: report,
                        onTap: () {
                          context.push('/lost-reports/${report.id}');
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Інформаційний блок над списком SOS.
class _ReportsSummaryCard extends StatelessWidget {
  final int reportCount;
  final bool isActiveView;

  const _ReportsSummaryCard({
    required this.reportCount,
    required this.isActiveView,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final backgroundColor = isActiveView
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;

    final foregroundColor = isActiveView
        ? colorScheme.onErrorContainer
        : colorScheme.onPrimaryContainer;

    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isActiveView
                  ? Icons.campaign_outlined
                  : Icons.check_circle_outline,
              size: 30,
              color: foregroundColor,
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActiveView
                        ? 'Активні пошуки'
                        : 'Завершені пошуки',
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isActiveView
                        ? reportCount == 0
                            ? 'Наразі немає активних SOS-оголошень.'
                            : 'Активних оголошень: $reportCount. Перегляньте їх або додайте свідчення.'
                        : reportCount == 0
                            ? 'Закритих SOS-оголошень ще немає.'
                            : 'Завершених оголошень: $reportCount.',
                    style: TextStyle(
                      color: foregroundColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}