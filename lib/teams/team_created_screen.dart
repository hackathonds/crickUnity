import 'package:flutter/material.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_state_scaffolds.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'team_models.dart';

/// PRD §6.1: "Creator becomes Team Owner + Captain... Creation grants
/// 'Founder' badge + 100 XP." No rewards ledger/badge-grant backend
/// exists yet (same gap as every other reward-on-action trigger this
/// session) -- this success screen states the outcome, it doesn't wire a
/// real grant.
class TeamCreatedScreen extends StatelessWidget {
  final Team team;
  final VoidCallback onDone;

  const TeamCreatedScreen({
    super.key,
    required this.team,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Center(child: AppArcIllustration(color: team.primaryColor)),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                '${team.name} is live!',
                style: AppTypography.h1.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                "You're the Owner and Captain. +100 XP · Founder badge "
                'earned.',
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              ),
              const Spacer(),
              AppButton(
                key: const ValueKey('teamCreatedDoneButton'),
                variant: AppButtonVariant.primary,
                label: 'Done',
                fullWidth: true,
                onPressed: onDone,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
