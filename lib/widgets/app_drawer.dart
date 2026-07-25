import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../roles/console_registry.dart';
import '../roles/current_roles_provider.dart';
import 'placeholder_screen.dart';

/// PRD §3.3's 5 drawer sections. Only "Consoles" is role-gated — it's
/// empty (and hidden) until the account holds a console-granting role
/// (non-negotiable #10: never a role picker, only ever a reflection of
/// activity already granted).
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  static const _myIdentity = [
    'Profile',
    'Wallet & Coins',
    'Rewards',
    'Achievements',
    'Activity Calendar',
    'Year in Review',
  ];

  static const _myCricket = [
    'My Teams',
    'My Matches',
    'My Tournaments',
    'My Bookings',
    'My Academy',
    'Availability settings',
  ];

  static const _money = ['Expenses', 'Settlements', 'Reports'];

  static const _settings = [
    'Privacy',
    'Notifications',
    'Language',
    'Help',
    'Report a Problem',
    'Log out',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final roles = ref.watch(currentRolesProvider);
    final consoles = consolesFor(roles);

    return Drawer(
      backgroundColor: colors.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: colors.surfaceAlt),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'CricUnity',
                style: AppTypography.h2.copyWith(color: colors.textPrimary),
              ),
            ),
          ),
          _DrawerSection(title: 'My Identity', items: _myIdentity),
          _DrawerSection(title: 'My Cricket', items: _myCricket),
          if (consoles.isNotEmpty)
            _DrawerSection(
              title: 'Consoles',
              items: consoles.map((c) => c.name).toList(),
            ),
          _DrawerSection(title: 'Money', items: _money),
          _DrawerSection(title: 'Settings', items: _settings),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  final String title;
  final List<String> items;

  const _DrawerSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Text(
            title,
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
        ),
        for (final item in items)
          ListTile(
            title: Text(item, style: AppTypography.body),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => PlaceholderScreen(title: item),
                ),
              );
            },
          ),
        const Divider(height: AppSpacing.xl),
      ],
    );
  }
}
