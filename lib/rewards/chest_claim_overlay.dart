import 'package:flutter/material.dart';

import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_motion.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';

/// DS §7-56's "chest (tap-burst)" claim overlay. Existing chest awards
/// (streak/mission/badge milestones) already mint coins instantly at
/// the moment they're earned (no unclaimed-chest queue exists across
/// those stories) -- this overlay is the reusable tap-burst reveal
/// component itself, exercised here via the Luck Layer hub's demo
/// chest. Retrofitting every existing instant chest award into a
/// claim-gated queue is a larger cross-story change than this one,
/// flagged rather than silently expanded into.
Future<void> showChestClaimOverlay(BuildContext context, {required int coins}) {
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: true,
    builder: (context) => _ChestClaimContent(coins: coins),
  );
}

class _ChestClaimContent extends StatefulWidget {
  final int coins;

  const _ChestClaimContent({required this.coins});

  @override
  State<_ChestClaimContent> createState() => _ChestClaimContentState();
}

class _ChestClaimContentState extends State<_ChestClaimContent> {
  bool _burst = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final reduced = AppMotion.isReduced(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            key: const ValueKey('chestTapBurstTarget'),
            onTap: () => setState(() => _burst = true),
            child: AnimatedScale(
              scale: _burst ? 1.3 : 1.0,
              duration: reduced
                  ? Duration.zero
                  : const Duration(milliseconds: 240),
              curve: Curves.elasticOut,
              child: Icon(
                _burst ? Icons.lock_open : Icons.card_giftcard,
                size: 64,
                color: colors.coin,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            _burst ? 'Chest opened! +${widget.coins} coins' : 'Tap to open',
            style: AppTypography.h2.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            key: const ValueKey('chestClaimDoneButton'),
            variant: AppButtonVariant.primary,
            label: _burst ? 'Claim' : 'Skip',
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
