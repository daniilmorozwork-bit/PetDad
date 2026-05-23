import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_section_card.dart';
import '../../data/models/public_pet_profile_model.dart';
import '../cubit/qr_cubit.dart';
import '../cubit/qr_state.dart';

/// Публічний профіль тварини, відкритий через QR-код.
/// Екран не показує приватні дані власника або службові дії.
class PublicQrProfileScreen extends StatefulWidget {
  final String token;

  const PublicQrProfileScreen({
    super.key,
    required this.token,
  });

  @override
  State<PublicQrProfileScreen> createState() =>
      _PublicQrProfileScreenState();
}

class _PublicQrProfileScreenState extends State<PublicQrProfileScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final qrCubit = context.read<QrCubit>();

      /// Фіксуємо факт відкриття публічного профілю.
      await qrCubit.registerScan(widget.token);

      /// Завантажуємо безпечні публічні дані тварини.
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QrCubit, QrState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
              ),
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
                return const _ProfileNotFoundState();
              }

              return Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _PublicPetHeroCard(
                        profile: profile,
                        speciesLabel: _speciesLabel(profile.species),
                      ),

                      const SizedBox(height: 12),

                      _PrivacyNoticeCard(
                        isLost: profile.status == 'lost',
                      ),

                      const SizedBox(height: 12),

                      AppSectionCard(
                        title: 'Основна інформація',
                        icon: Icons.pets_outlined,
                        child: Column(
                          children: [
                            _InfoRow(
                              label: 'Вид',
                              value: _speciesLabel(profile.species),
                            ),
                            _InfoRow(
                              label: 'Порода',
                              value: profile.breed?.trim().isNotEmpty == true
                                  ? profile.breed!
                                  : 'Не вказано',
                            ),
                            _InfoRow(
                              label: 'Стать',
                              value: _genderLabel(profile.gender),
                            ),
                            _InfoRow(
                              label: 'Окрас',
                              value: profile.color,
                              showDivider: false,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      AppSectionCard(
                        title: 'Особливі прикмети',
                        icon: Icons.description_outlined,
                        child: Text(
                          profile.specialMarks?.trim().isNotEmpty == true
                              ? profile.specialMarks!
                              : 'Особливі прикмети не вказані.',
                        ),
                      ),

                      if (profile.status == 'lost') ...[
                        const SizedBox(height: 12),
                        const AppSectionCard(
                          title: 'Як допомогти',
                          icon: Icons.volunteer_activism_outlined,
                          child: Text(
                            'Якщо ви бачили цю тварину, зверніть увагу '
                            'на місце та час спостереження. '
                            'Повідомити про побачену тварину можна '
                            'через активне SOS-оголошення у застосунку PetDad.',
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      Text(
                        'Публічний профіль не містить приватних контактних '
                        'даних власника.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),

                  if (state.isLoading)
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

/// Верхня картка публічного профілю з фото, назвою та статусом.
class _PublicPetHeroCard extends StatelessWidget {
  final PublicPetProfileModel profile;
  final String speciesLabel;

  const _PublicPetHeroCard({
    required this.profile,
    required this.speciesLabel,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = AppConfig.buildFileUrl(profile.mainPhotoUrl);

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
              child: PetStatusBadge(
                status: profile.status,
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 46, 16, 16),
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
                      profile.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profile.breed?.trim().isNotEmpty == true
                          ? '$speciesLabel • ${profile.breed}'
                          : speciesLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
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

/// Інформаційний блок про публічність профілю або активний пошук.
class _PrivacyNoticeCard extends StatelessWidget {
  final bool isLost;

  const _PrivacyNoticeCard({
    required this.isLost,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final backgroundColor = isLost
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;

    final foregroundColor = isLost
        ? colorScheme.onErrorContainer
        : colorScheme.onPrimaryContainer;

    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isLost
                  ? Icons.campaign_outlined
                  : Icons.shield_outlined,
              color: foregroundColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isLost
                    ? 'Ця тварина позначена як зникла. '
                        'Будь-яке точне спостереження може допомогти пошуку.'
                    : 'Це публічний профіль, відкритий через QR-код. '
                        'Приватні дані власника приховано.',
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

/// Рядок характеристики публічного профілю.
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

/// Стан, коли QR-код недійсний або профіль недоступний.
class _ProfileNotFoundState extends StatelessWidget {
  const _ProfileNotFoundState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.qr_code_2_outlined,
              size: 74,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Профіль недоступний',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'QR-код може бути неактивним або профіль більше не є публічним.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}