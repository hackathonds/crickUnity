import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/theme/app_theme.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_radius.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'appearance_settings_provider.dart';

const Map<AppThemeId, String> _themeNames = {
  AppThemeId.theme1: 'Modern Cricket Green',
  AppThemeId.theme2: 'Royal Navy Gold',
  AppThemeId.theme3: 'Electric Blue',
  AppThemeId.theme4: 'Dark Graphite Neon',
  AppThemeId.theme5: 'Premium White Emerald',
};

/// DS §7 screen 67 "Appearance": theme cards live-preview (mini Home render
/// per theme), text-size slider with live sample, reduced-motion toggle.
///
/// Screen 67 also covers Privacy (a separate story, E16-01) inside a wider
/// "Settings hub" that doesn't exist as its own backlog story yet -- this
/// screen is reached via a temporary direct link from the Profile tab
/// (see app_router.dart) until that hub is built.
///
/// This screen performs no network/auth I/O -- every choice here is
/// synchronous, in-memory app state -- so of the 7 canonical states (DS §6)
/// only Default and a light selection-feedback Success apply; Loading,
/// Error, Offline, and Permission-denied have no real trigger and aren't
/// fabricated.
class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appearanceSettingsProvider);
    final notifier = ref.read(appearanceSettingsProvider.notifier);
    final colors = Theme.of(context).extension<AppColors>()!;
    final scale = settings.textScaleOverride ?? 1.0;

    Widget sectionLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppTypography.label.copyWith(color: colors.textTertiary),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          sectionLabel('Theme'),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _ThemeCard(
                key: const ValueKey('appearanceThemeCard_system'),
                label: 'System',
                selected: settings.themeOverride == null,
                onTap: () => notifier.setThemeOverride(null),
                preview: _SplitMockup(
                  leftColors: AppTheme.themes[AppTheme.defaultLight]!
                      .extension<AppColors>()!,
                  rightColors: AppTheme.themes[AppTheme.defaultDark]!
                      .extension<AppColors>()!,
                ),
              ),
              for (final id in AppThemeId.values)
                _ThemeCard(
                  key: ValueKey('appearanceThemeCard_${id.name}'),
                  label: _themeNames[id]!,
                  selected: settings.themeOverride == id,
                  onTap: () => notifier.setThemeOverride(id),
                  preview: _Mockup(
                    colors: AppTheme.themes[id]!.extension<AppColors>()!,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          sectionLabel('Text size'),
          Slider(
            key: const ValueKey('appearanceTextScaleSlider'),
            value: scale,
            min: 1.0,
            max: AppTypography.maxTextScaleFactor,
            divisions: 7,
            label: '${(scale * 100).round()}%',
            onChanged: notifier.setTextScale,
          ),
          Text(
            'The quick brown fox scores a century.',
            key: const ValueKey('appearanceTextScaleSample'),
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xxl),
          sectionLabel('Motion'),
          SizedBox(
            height: 48,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Reduce motion',
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Switch(
                  key: const ValueKey('appearanceReducedMotionSwitch'),
                  value: settings.reducedMotionOverride,
                  activeThumbColor: colors.primary,
                  onChanged: notifier.setReducedMotionOverride,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget preview;

  const _ThemeCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: AppRadius.mdRadius,
              border: Border.all(
                color: selected ? colors.primary : colors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: preview,
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: 96,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: selected ? colors.primary : colors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// A tiny representative mockup of a themed screen (app-bar strip, a card
/// with a `live` dot, a primary button) -- not a literal Home-tab render
/// (Home's real content ships in a later epic), standing in for DS §7
/// screen 67's "mini Home render per theme".
class _Mockup extends StatelessWidget {
  final AppColors colors;

  const _Mockup({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.bg,
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(child: Container(height: 6, color: colors.textPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colors.live,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(height: 4, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

/// The "System" theme card's preview: a light/dark split so it reads as
/// "adapts automatically" rather than a 6th fixed theme.
class _SplitMockup extends StatelessWidget {
  final AppColors leftColors;
  final AppColors rightColors;

  const _SplitMockup({required this.leftColors, required this.rightColors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Mockup(colors: leftColors)),
        Container(width: 1, color: leftColors.divider),
        Expanded(child: _Mockup(colors: rightColors)),
      ],
    );
  }
}
