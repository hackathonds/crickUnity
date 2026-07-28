import 'package:flutter/material.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';

/// E16-10 pairs "Localization" with an accessibility audit pass, but
/// localization/i18n is never described anywhere in either frozen source
/// document: no supported-language list, no translated-string system, no
/// locale switcher. Checked both documents in full for
/// "localization"/"i18n"/"language"/"translat" -- the only hits are
/// DS §10's forward-looking "RTL mirror spec" requirement for *future*
/// new components (a design rule, not a shipped feature) and PRD §5.1's
/// "languages" profile field (a player's own spoken languages, unrelated
/// to app UI translation). Per this project's rule to never invent
/// behavior for a genuinely absent detail, this is an explicit gap
/// notice rather than a guessed language picker -- same treatment E16-09
/// gave Wearable glances.
class LocalizationSettingsScreen extends StatelessWidget {
  const LocalizationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Language')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Container(
          key: const ValueKey('localizationGapNotice'),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            'Localization has no design or behavior spec in the PRD or '
            'Design Spec -- no supported-language list, translated-string '
            'system, or locale switcher is named anywhere. Flagging as an '
            'open question rather than guessing: which languages, and '
            'does the app translate UI copy or just accept them as a '
            'profile field?',
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
        ),
      ),
    );
  }
}
