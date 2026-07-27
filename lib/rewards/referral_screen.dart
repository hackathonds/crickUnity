import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'referral_models.dart';
import 'referral_provider.dart';

/// DS §11.14: "Referral: hero code card (copy/share big targets),
/// progress list of referees with state chips (Joined -> First verified
/// match = both reward rows), terms accordion." No real invite/
/// contacts pipeline exists -- "Simulate friend joins" stands in for a
/// real invite send, same convention as every other missing-
/// integration gap this session.
class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final referral = ref.watch(referralProvider);
    final notifier = ref.read(referralProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Refer a friend')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your code',
                  style: AppTypography.label.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  referral.code,
                  key: const ValueKey('referralCodeText'),
                  style: AppTypography.h1.copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        key: const ValueKey('copyReferralCodeButton'),
                        variant: AppButtonVariant.secondary,
                        label: 'Copy',
                        fullWidth: true,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: referral.code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code copied')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(
                        key: const ValueKey('shareReferralCodeButton'),
                        variant: AppButtonVariant.primary,
                        label: 'Share',
                        fullWidth: true,
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(
                              text:
                                  'Join me on CricUnity! Use my code '
                                  '${referral.code}',
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Share link copied')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Invite a friend (debug)',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  key: const ValueKey('inviteFriendNameField'),
                  label: "Friend's name",
                  controller: _nameController,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                key: const ValueKey('simulateFriendJoinsButton'),
                variant: AppButtonVariant.secondary,
                label: 'Simulate join',
                onPressed: () {
                  if (_nameController.text.trim().isEmpty) return;
                  notifier.inviteFriend(_nameController.text.trim());
                  _nameController.clear();
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Your referrals',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (referral.referrals.isEmpty)
            Text(
              'No referrals yet.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else
            for (final entry in referral.referrals)
              Container(
                key: ValueKey('referralRow_${entry.id}'),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.name,
                        style: AppTypography.body.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    AppTagChip(
                      label: referralStatusLabels[entry.status]!,
                      variant: entry.status == ReferralStatus.firstMatchVerified
                          ? AppTagChipVariant.success
                          : AppTagChipVariant.neutral,
                    ),
                    if (entry.status == ReferralStatus.joined) ...[
                      const SizedBox(width: AppSpacing.sm),
                      AppButton(
                        key: ValueKey('simulateFirstMatchButton_${entry.id}'),
                        variant: AppButtonVariant.tertiary,
                        label: 'Simulate 1st match',
                        onPressed: () =>
                            notifier.markFirstVerifiedMatch(entry.id),
                      ),
                    ],
                  ],
                ),
              ),
          const SizedBox(height: AppSpacing.xxl),
          ExpansionTile(
            key: const ValueKey('referralTermsAccordion'),
            title: Text(
              'Terms',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  'You earn 100 coins + 100 XP, and your friend earns 50 '
                  'coins + 50 XP, once they play their first verified '
                  'match on CricUnity.',
                  style: AppTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
