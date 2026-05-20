import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../cubit/qr_cubit.dart';
import '../cubit/qr_state.dart';

/// Екран QR-коду конкретної тварини.
class PetQrScreen extends StatefulWidget {
  final String petId;

  const PetQrScreen({
    super.key,
    required this.petId,
  });

  @override
  State<PetQrScreen> createState() => _PetQrScreenState();
}

class _PetQrScreenState extends State<PetQrScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QrCubit>().loadActiveQr(widget.petId);
    });
  }

  Future<void> _generateQr() async {
    await context.read<QrCubit>().generateQr(widget.petId);
  }

  Future<void> _confirmReissue() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Перевипустити QR-код?'),
          content: const Text(
            'Старий QR-код стане неактивним. Його більше не можна буде використовувати.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Скасувати'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Перевипустити'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await context.read<QrCubit>().reissueQr(widget.petId);
    }
  }

  Future<void> _copyUrl(String url) async {
    await Clipboard.setData(
      ClipboardData(text: url),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Посилання скопійовано'),
        ),
      );
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

        if (state.successMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(state.successMessage!)),
            );

          context.read<QrCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        final qrCode = state.qrCode;

        return Scaffold(
          appBar: AppBar(
            title: const Text('QR-код тварини'),
          ),
          body: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (qrCode == null) ...[
                    const SizedBox(height: 80),
                    Icon(
                      Icons.qr_code_2,
                      size: 96,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'QR-код ще не створено',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Створіть QR-код, щоб інші люди могли відкрити публічний профіль тварини.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: state.isLoading ? null : _generateQr,
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Створити QR-код'),
                    ),
                  ] else ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            QrImageView(
                              data: qrCode.publicUrl,
                              version: QrVersions.auto,
                              size: 260,
                              backgroundColor: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              qrCode.isActive
                                  ? 'Активний QR-код'
                                  : 'Неактивний QR-код',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: qrCode.isActive
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Публічне посилання',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),

                    SelectableText(
                      qrCode.publicUrl,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: () => _copyUrl(qrCode.publicUrl),
                      icon: const Icon(Icons.copy),
                      label: const Text('Скопіювати посилання'),
                    ),
                    const SizedBox(height: 8),

                    FilledButton.icon(
                      onPressed: state.isLoading ? null : _confirmReissue,
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Перевипустити QR-код'),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Пояснення',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Цей QR-код веде на публічний профіль тварини. У профілі не показуються приватні дані власника.',
                    ),
                  ],
                ],
              ),

              if (state.isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.08),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}