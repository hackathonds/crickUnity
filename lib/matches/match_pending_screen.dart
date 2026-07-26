import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';

/// DS §7 screen 24: "Send -> opponent-pending state screen with share
/// nudge." No real deep-link/share-sheet integration exists yet -- the
/// nudge is a plain "copy link" action, same honest-gap pattern as the
/// QR-code placeholder in Team Invite (E3-03).
class MatchPendingScreen extends StatelessWidget {
  final String opponentTeamName;
  final VoidCallback onDone;

  const MatchPendingScreen({
    super.key,
    required this.opponentTeamName,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Match sent')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              key: const ValueKey('matchPendingHeadline'),
              'Waiting on $opponentTeamName',
              style: AppTypography.h2.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "$opponentTeamName's captain can Accept, propose a change, "
              'or decline. Nudge them along by sharing the invite.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: const ValueKey('shareInviteLinkButton'),
              variant: AppButtonVariant.secondary,
              label: 'Copy invite link',
              fullWidth: true,
              onPressed: () {
                Clipboard.setData(
                  const ClipboardData(
                    text: 'https://cricunity.app/match-invite/mock',
                  ),
                );
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Link copied')));
              },
            ),
            const Spacer(),
            AppButton(
              key: const ValueKey('matchPendingDoneButton'),
              variant: AppButtonVariant.primary,
              label: 'Done',
              fullWidth: true,
              onPressed: onDone,
            ),
          ],
        ),
      ),
    );
  }
}
