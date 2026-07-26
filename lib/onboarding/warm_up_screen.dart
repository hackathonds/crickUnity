import 'package:flutter/material.dart';

import '../design_system/components/app_avatar.dart';
import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_radius.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';

/// DS §11.3 Interest warm-up: "follow-suggestion cards (no role question
/// -- PRD rule); [Done] lands on Home with Onboarding-Checklist widget
/// active." The Onboarding-Checklist widget itself belongs to the Home
/// dashboard (a later epic) -- out of scope here; [onDone] just signals
/// this flow is finished.
///
/// No real social graph exists to suggest from -- these are mock names,
/// same category as the OTP demo code and city list.
const List<String> _suggestedNames = [
  'Arjun Rao',
  'Priya Nair',
  'Kabir Singh',
  'Ananya Iyer',
];

class WarmUpScreen extends StatefulWidget {
  final VoidCallback onDone;

  const WarmUpScreen({super.key, required this.onDone});

  @override
  State<WarmUpScreen> createState() => _WarmUpScreenState();
}

class _WarmUpScreenState extends State<WarmUpScreen> {
  final Set<String> _followed = {};

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Follow some players')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'People to follow',
              style: AppTypography.h2.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "We'll show you their matches and updates.",
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Expanded(
              child: ListView.separated(
                itemCount: _suggestedNames.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final name = _suggestedNames[index];
                  final isFollowed = _followed.contains(name);
                  return Container(
                    key: ValueKey('warmUpSuggestion_$index'),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border.all(color: colors.border),
                      borderRadius: AppRadius.mdRadius,
                    ),
                    child: Row(
                      children: [
                        AppAvatar(size: AppAvatarSize.sm, name: name),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            name,
                            style: AppTypography.body.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        AppButton(
                          key: ValueKey('warmUpFollowButton_$index'),
                          variant: isFollowed
                              ? AppButtonVariant.secondary
                              : AppButtonVariant.primary,
                          label: isFollowed ? 'Following' : 'Follow',
                          onPressed: () => setState(() {
                            if (isFollowed) {
                              _followed.remove(name);
                            } else {
                              _followed.add(name);
                            }
                          }),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            AppButton(
              key: const ValueKey('warmUpDone'),
              variant: AppButtonVariant.primary,
              label: 'Done',
              fullWidth: true,
              onPressed: widget.onDone,
            ),
          ],
        ),
      ),
    );
  }
}
