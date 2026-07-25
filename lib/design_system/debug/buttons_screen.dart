import 'package:flutter/material.dart';

import '../components/app_button.dart';
import '../icons/app_icon_id.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// QA tool for E0-07 (sub-task 1/10): every button variant across its
/// enabled/disabled/loading states, plus selected states for the
/// icon/chip-action buttons.
class ButtonsScreen extends StatefulWidget {
  const ButtonsScreen({super.key});

  @override
  State<ButtonsScreen> createState() => _ButtonsScreenState();
}

class _ButtonsScreenState extends State<ButtonsScreen> {
  bool _loading = false;
  bool _chipSelected = false;
  bool _iconSelected = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    Widget section(String title, Widget child) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.h2.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Buttons (QA)')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          section(
            'Primary',
            Column(
              children: [
                AppButton(
                  variant: AppButtonVariant.primary,
                  label: 'Primary enabled',
                  onPressed: () {},
                ),
                const SizedBox(height: AppSpacing.sm),
                const AppButton(
                  variant: AppButtonVariant.primary,
                  label: 'Primary disabled',
                  onPressed: null,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  variant: AppButtonVariant.primary,
                  label: 'Primary loading',
                  isLoading: _loading,
                  onPressed: () => setState(() => _loading = !_loading),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  variant: AppButtonVariant.primary,
                  label: 'With icon',
                  icon: AppIconId.plus,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          section(
            'Secondary',
            Column(
              children: [
                AppButton(
                  variant: AppButtonVariant.secondary,
                  label: 'Secondary enabled',
                  onPressed: () {},
                ),
                const SizedBox(height: AppSpacing.sm),
                const AppButton(
                  variant: AppButtonVariant.secondary,
                  label: 'Secondary disabled',
                  onPressed: null,
                ),
              ],
            ),
          ),
          section(
            'Tertiary',
            AppButton(
              variant: AppButtonVariant.tertiary,
              label: 'Tertiary',
              onPressed: () {},
            ),
          ),
          section(
            'Destructive',
            AppButton(
              variant: AppButtonVariant.destructive,
              label: 'Delete team',
              onPressed: () {},
            ),
          ),
          section(
            'Chip-action',
            Row(
              children: [
                AppChipActionButton(
                  label: 'Yes',
                  selected: _chipSelected,
                  onPressed: () =>
                      setState(() => _chipSelected = !_chipSelected),
                ),
                const SizedBox(width: AppSpacing.sm),
                const AppChipActionButton(label: 'No', onPressed: null),
              ],
            ),
          ),
          section(
            'Icon button',
            Row(
              children: [
                AppIconButton(
                  icon: AppIconId.heart,
                  semanticLabel: 'Like',
                  selected: _iconSelected,
                  onPressed: () =>
                      setState(() => _iconSelected = !_iconSelected),
                ),
                const SizedBox(width: AppSpacing.sm),
                const AppIconButton(
                  icon: AppIconId.heart,
                  semanticLabel: 'Like (disabled)',
                  onPressed: null,
                ),
              ],
            ),
          ),
          section(
            'FAB',
            AppFab(
              icon: AppIconId.plus,
              semanticLabel: 'Create',
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
