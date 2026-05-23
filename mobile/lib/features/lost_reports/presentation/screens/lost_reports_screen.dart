import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubit/lost_reports_cubit.dart';
import '../cubit/lost_reports_state.dart';
import '../widgets/lost_report_card.dart';
import '../../../../shared/widgets/app_section_scaffold.dart';


/// Екран активних SOS-оголошень.
class LostReportsScreen extends StatefulWidget {
  const LostReportsScreen({super.key});

  @override
  State<LostReportsScreen> createState() => _LostReportsScreenState();
}

class _LostReportsScreenState extends State<LostReportsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LostReportsCubit>().loadLostReports();
    });
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
        return AppSectionScaffold(
          title: 'SOS-пошук',
          currentRoute: '/lost-reports',
          body: RefreshIndicator(
            onRefresh: () =>
                context.read<LostReportsCubit>().loadLostReports(),
            child: Builder(
              builder: (context) {
                if (state.isLoading && state.reports.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state.reports.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 120),
                      Icon(
                        Icons.campaign_outlined,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Активних SOS немає',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'SOS створюється з профілю конкретної тварини.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.reports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final report = state.reports[index];

                    return LostReportCard(
                      report: report,
                      onTap: () {
                        context.push('/lost-reports/${report.id}');
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}