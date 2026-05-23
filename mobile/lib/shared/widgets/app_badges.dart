import 'package:flutter/material.dart';

/// Внутрішні кольорові типи позначок.
enum _BadgeTone {
  neutral,
  success,
  warning,
  danger,
  info,
}

/// Базова візуальна позначка.
/// Напряму на екранах не використовується:
/// замість неї застосовуються PetStatusBadge, ReportStatusBadge тощо.
class _AppBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final _BadgeTone tone;

  const _AppBadge({
    required this.label,
    required this.icon,
    required this.tone,
  });

  Color _seedColor() {
    switch (tone) {
      case _BadgeTone.success:
        return Colors.green;
      case _BadgeTone.warning:
        return Colors.orange;
      case _BadgeTone.danger:
        return Colors.red;
      case _BadgeTone.info:
        return Colors.blue;
      case _BadgeTone.neutral:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeColorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor(),
      brightness: Theme.of(context).brightness,
    );

    return Chip(
      avatar: Icon(
        icon,
        size: 16,
        color: badgeColorScheme.onSecondaryContainer,
      ),
      label: Text(label),
      labelStyle: TextStyle(
        color: badgeColorScheme.onSecondaryContainer,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: badgeColorScheme.secondaryContainer,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

/// Статус профілю тварини.
class PetStatusBadge extends StatelessWidget {
  final String status;

  const PetStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'owned':
        return const _AppBadge(
          label: 'Вдома',
          icon: Icons.home_outlined,
          tone: _BadgeTone.success,
        );
      case 'lost':
        return const _AppBadge(
          label: 'Зникла',
          icon: Icons.campaign_outlined,
          tone: _BadgeTone.danger,
        );
      case 'found':
        return const _AppBadge(
          label: 'Знайдена',
          icon: Icons.pets_outlined,
          tone: _BadgeTone.info,
        );
      case 'archived':
        return const _AppBadge(
          label: 'Архівована',
          icon: Icons.archive_outlined,
          tone: _BadgeTone.neutral,
        );
      default:
        return _AppBadge(
          label: status,
          icon: Icons.info_outline,
          tone: _BadgeTone.neutral,
        );
    }
  }
}

/// Статус SOS-оголошення.
class ReportStatusBadge extends StatelessWidget {
  final String status;

  const ReportStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'active':
        return const _AppBadge(
          label: 'Активний SOS',
          icon: Icons.campaign_outlined,
          tone: _BadgeTone.danger,
        );
      case 'closed':
        return const _AppBadge(
          label: 'SOS закрито',
          icon: Icons.check_circle_outline,
          tone: _BadgeTone.success,
        );
      case 'cancelled':
        return const _AppBadge(
          label: 'SOS скасовано',
          icon: Icons.cancel_outlined,
          tone: _BadgeTone.neutral,
        );
      default:
        return _AppBadge(
          label: status,
          icon: Icons.info_outline,
          tone: _BadgeTone.neutral,
        );
    }
  }
}

/// Статус свідчення.
class SightingStatusBadge extends StatelessWidget {
  final String status;

  const SightingStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'active':
        return const _AppBadge(
          label: 'Нове свідчення',
          icon: Icons.visibility_outlined,
          tone: _BadgeTone.info,
        );
      case 'confirmed':
        return const _AppBadge(
          label: 'Підтверджене',
          icon: Icons.verified_outlined,
          tone: _BadgeTone.success,
        );
      case 'rejected':
        return const _AppBadge(
          label: 'Відхилене',
          icon: Icons.block_outlined,
          tone: _BadgeTone.neutral,
        );
      default:
        return _AppBadge(
          label: status,
          icon: Icons.info_outline,
          tone: _BadgeTone.neutral,
        );
    }
  }
}

/// Рівень впевненості свідка.
class ConfidenceBadge extends StatelessWidget {
  final String level;

  const ConfidenceBadge({
    super.key,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    switch (level) {
      case 'high':
        return const _AppBadge(
          label: 'Висока впевненість',
          icon: Icons.verified_outlined,
          tone: _BadgeTone.success,
        );
      case 'medium':
        return const _AppBadge(
          label: 'Середня впевненість',
          icon: Icons.help_outline,
          tone: _BadgeTone.warning,
        );
      case 'low':
        return const _AppBadge(
          label: 'Низька впевненість',
          icon: Icons.help_outline,
          tone: _BadgeTone.neutral,
        );
      default:
        return _AppBadge(
          label: level,
          icon: Icons.info_outline,
          tone: _BadgeTone.neutral,
        );
    }
  }
}

/// Тип події, що відображається на карті.
class MapEventTypeBadge extends StatelessWidget {
  final String type;

  const MapEventTypeBadge({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case 'lost_pet':
        return const _AppBadge(
          label: 'SOS',
          icon: Icons.campaign_outlined,
          tone: _BadgeTone.danger,
        );
      case 'sighting':
        return const _AppBadge(
          label: 'Свідчення',
          icon: Icons.visibility_outlined,
          tone: _BadgeTone.warning,
        );
      case 'found_pet':
        return const _AppBadge(
          label: 'Знайдена тварина',
          icon: Icons.pets_outlined,
          tone: _BadgeTone.success,
        );
      case 'qr_scan':
        return const _AppBadge(
          label: 'QR-сканування',
          icon: Icons.qr_code_scanner_outlined,
          tone: _BadgeTone.info,
        );
      default:
        return _AppBadge(
          label: type,
          icon: Icons.location_on_outlined,
          tone: _BadgeTone.neutral,
        );
    }
  }
}