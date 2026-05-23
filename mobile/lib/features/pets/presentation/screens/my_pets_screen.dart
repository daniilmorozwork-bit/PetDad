import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_section_scaffold.dart';
import '../cubit/pets_cubit.dart';
import '../cubit/pets_state.dart';
import '../widgets/pet_card.dart';

/// Екран списку тварин користувача.
class MyPetsScreen extends StatefulWidget {
  const MyPetsScreen({super.key});

  @override
  State<MyPetsScreen> createState() => _MyPetsScreenState();
}

class _MyPetsScreenState extends State<MyPetsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PetsCubit>().loadMyPets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PetsCubit, PetsState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
              ),
            );

          context.read<PetsCubit>().clearMessages();
        }

        if (state.successMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
              ),
            );

          context.read<PetsCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        final lostCount = state.pets
            .where((pet) => pet.status == 'lost')
            .length;

        final homeCount = state.pets
            .where((pet) => pet.status == 'owned')
            .length;

        return AppSectionScaffold(
          title: 'Мої тварини',
          currentRoute: '/pets',
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              context.push('/pets/create');
            },
            icon: const Icon(Icons.add),
            label: const Text('Додати'),
          ),
          body: RefreshIndicator(
            onRefresh: () => context.read<PetsCubit>().loadMyPets(),
            child: Builder(
              builder: (context) {
                if (state.isLoading && state.pets.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state.pets.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      AppEmptyState(
                        icon: Icons.pets_outlined,
                        title: 'У вас ще немає тварин',
                        message:
                            'Створіть профіль тварини, щоб додати фото, '
                            'QR-код і за потреби створити SOS-пошук.',
                        action: FilledButton.icon(
                          onPressed: () {
                            context.push('/pets/create');
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Додати тварину'),
                        ),
                      ),
                    ],
                  );
                }

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  children: [
                    _PetsSummaryCard(
                      totalCount: state.pets.length,
                      homeCount: homeCount,
                      lostCount: lostCount,
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Профілі тварин',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${state.pets.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    ...state.pets.map(
                      (pet) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: PetCard(
                          pet: pet,
                          onTap: () {
                            context.push('/pets/${pet.id}');
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// Верхній інформаційний блок списку тварин.
class _PetsSummaryCard extends StatelessWidget {
  final int totalCount;
  final int homeCount;
  final int lostCount;

  const _PetsSummaryCard({
    required this.totalCount,
    required this.homeCount,
    required this.lostCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: lostCount > 0
          ? colorScheme.errorContainer
          : colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              lostCount > 0 ? Icons.campaign_outlined : Icons.pets_outlined,
              color: lostCount > 0
                  ? colorScheme.onErrorContainer
                  : colorScheme.onPrimaryContainer,
              size: 30,
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lostCount > 0
                        ? 'Активний пошук тварин'
                        : 'Ваші профілі тварин',
                    style: TextStyle(
                      color: lostCount > 0
                          ? colorScheme.onErrorContainer
                          : colorScheme.onPrimaryContainer,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lostCount > 0
                        ? 'Зниклих тварин: $lostCount. Вдома: $homeCount.'
                        : 'Додано профілів: $totalCount. Усі тварини мають статус «Вдома».',
                    style: TextStyle(
                      color: lostCount > 0
                          ? colorScheme.onErrorContainer
                          : colorScheme.onPrimaryContainer,
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