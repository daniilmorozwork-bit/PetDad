import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
              SnackBar(content: Text(state.errorMessage!)),
            );

          context.read<PetsCubit>().clearMessages();
        }

        if (state.successMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(state.successMessage!)),
            );

          context.read<PetsCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Мої тварини'),
          ),
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
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 120),
                      Icon(
                        Icons.pets,
                        size: 72,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'У вас ще немає доданих тварин',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Створіть профіль тварини, щоб згодом додати фото, QR-код і SOS-пошук.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.push('/pets/create');
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Додати тварину'),
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.pets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final pet = state.pets[index];

                    return PetCard(
                      pet: pet,
                      onTap: () {
                        context.push('/pets/${pet.id}');
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