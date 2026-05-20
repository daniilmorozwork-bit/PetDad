import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../cubit/qr_cubit.dart';
import '../cubit/qr_state.dart';

/// Публічний профіль тварини, відкритий через QR token.
class PublicQrProfileScreen extends StatefulWidget {
  final String token;

  const PublicQrProfileScreen({
    super.key,
    required this.token,
  });

  @override
  State<PublicQrProfileScreen> createState() => _PublicQrProfileScreenState();
}

class _PublicQrProfileScreenState extends State<PublicQrProfileScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final qrCubit = context.read<QrCubit>();

      await qrCubit.registerScan(widget.token);
      await qrCubit.loadPublicProfile(widget.token);
    });
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

  String _genderLabel(String gender) {
    switch (gender) {
      case 'male':
        return 'Самець';
      case 'female':
        return 'Самка';
      default:
        return 'Невідомо';
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'owned':
        return 'Вдома';
      case 'lost':
        return 'Зникла';
      case 'found':
        return 'Знайдена';
      case 'archived':
        return 'Архів';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QrCubit, QrState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );

          context.read<QrCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        final profile = state.publicProfile;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Публічний профіль'),
          ),
          body: Builder(
            builder: (context) {
              if (state.isLoading && profile == null) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (profile == null) {
                return const Center(
                  child: Text('Профіль не знайдено'),
                );
              }

              final photoUrl = AppConfig.buildFileUrl(profile.mainPhotoUrl);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 240,
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
                    profile.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),

                  Chip(
                    label: Text(_statusLabel(profile.status)),
                  ),
                  const SizedBox(height: 16),

                  _InfoRow(label: 'Вид', value: _speciesLabel(profile.species)),
                  _InfoRow(label: 'Порода', value: profile.breed ?? 'Не вказано'),
                  _InfoRow(label: 'Стать', value: _genderLabel(profile.gender)),
                  _InfoRow(label: 'Окрас', value: profile.color),
                  _InfoRow(
                    label: 'Особливі прикмети',
                    value: profile.specialMarks ?? 'Не вказано',
                  ),

                  const SizedBox(height: 24),

                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Якщо ви знайшли або бачили цю тварину, звʼяжіться з власником через застосунок PetDad. Контактні дані власника не показуються у публічному профілі.',
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

/// Рядок характеристики.
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
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