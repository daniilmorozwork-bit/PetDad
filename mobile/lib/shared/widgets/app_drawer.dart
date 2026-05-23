import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/notifications/presentation/cubit/notifications_cubit.dart';
import '../../features/notifications/presentation/cubit/notifications_state.dart';

/// Бокове меню основних розділів застосунку.
class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({
    super.key,
    required this.currentRoute,
  });

  void _openSection(BuildContext context, String route) {
    Navigator.of(context).pop();

    if (route != currentRoute) {
      context.go(route);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final authCubit = context.read<AuthCubit>();

    Navigator.of(context).pop();

    await authCubit.logout();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;

    String userName = 'Користувач';
    String userEmail = '';

    if (authState is AuthAuthenticated) {
      userName = authState.user.fullName;
      userEmail = authState.user.email;
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (userEmail.isNotEmpty)
                          Text(
                            userEmail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerTile(
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home,
                    title: 'Головна',
                    isSelected: currentRoute == '/home',
                    onTap: () => _openSection(context, '/home'),
                  ),
                  _DrawerTile(
                    icon: Icons.pets_outlined,
                    selectedIcon: Icons.pets,
                    title: 'Мої тварини',
                    isSelected: currentRoute == '/pets',
                    onTap: () => _openSection(context, '/pets'),
                  ),
                  _DrawerTile(
                    icon: Icons.map_outlined,
                    selectedIcon: Icons.map,
                    title: 'Карта подій',
                    isSelected: currentRoute == '/map',
                    onTap: () => _openSection(context, '/map'),
                  ),
                  _DrawerTile(
                    icon: Icons.campaign_outlined,
                    selectedIcon: Icons.campaign,
                    title: 'SOS-пошук',
                    isSelected: currentRoute == '/lost-reports',
                    onTap: () => _openSection(context, '/lost-reports'),
                  ),
                  BlocBuilder<NotificationsCubit, NotificationsState>(
                    builder: (context, state) {
                      return _DrawerTile(
                        icon: Icons.notifications_outlined,
                        selectedIcon: Icons.notifications,
                        title: 'Повідомлення',
                        isSelected: currentRoute == '/notifications',
                        trailing: state.unreadCount > 0
                            ? _UnreadBadge(count: state.unreadCount)
                            : null,
                        onTap: () => _openSection(context, '/notifications'),
                      );
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings,
                    title: 'Налаштування',
                    isSelected: currentRoute == '/settings',
                    onTap: () => _openSection(context, '/settings'),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Вийти'),
              onTap: () => _logout(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Пункт бокового меню.
class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String title;
  final bool isSelected;
  final Widget? trailing;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.selectedIcon,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: isSelected,
      selectedTileColor:
          Theme.of(context).colorScheme.primaryContainer.withOpacity(0.42),
      leading: Icon(isSelected ? selectedIcon : icon),
      title: Text(title),
      trailing: trailing,
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

/// Індикатор кількості непрочитаних повідомлень.
class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : count.toString();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}