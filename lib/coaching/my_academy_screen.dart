import 'package:flutter/material.dart';

import '../design_system/components/app_card.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'compliance_vault_screen.dart';
import 'personal_training_log_screen.dart';

/// No student-facing academy-enrollment model exists anywhere in this
/// codebase -- `lib/academies/academy_models.dart`'s `Student`/`Batch`/
/// `FeeLedgerEntry` are entirely owner/coach-side (no link to "the
/// current viewer's own account"), and `AcademyConsoleScreen` is
/// confirmed owner/coach-only (already wired as the drawer's separate
/// "Academy Console" item). Per CLAUDE.md's "never guess behavior" rule,
/// no batch/fee/enrollment list is invented here. Instead this links out
/// to the two screens that genuinely are student-facing today: the Drill
/// Library / Personal Training Log (E11-05, explicitly "for ALL users,
/// not just academy students") and the Compliance Vault (E11-04).
class MyAcademyScreen extends StatelessWidget {
  const MyAcademyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('My Academy')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Text(
              "No academy enrollment is on record for your account yet -- "
              'here are the training tools available to every player.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
          ),
          Padding(
            key: const ValueKey('myAcademyTrainingLogLink'),
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _LinkCard(
              title: 'Personal Training Log',
              subtitle: 'Log drills, track PBs, and earn badges.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PersonalTrainingLogScreen(),
                ),
              ),
            ),
          ),
          Padding(
            key: const ValueKey('myAcademyComplianceVaultLink'),
            padding: EdgeInsets.zero,
            child: _LinkCard(
              title: 'Compliance Vault',
              subtitle: 'Certifications, consent forms, and expiries.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ComplianceVaultScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LinkCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.title.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colors.textTertiary),
        ],
      ),
    );
  }
}
