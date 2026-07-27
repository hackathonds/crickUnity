import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_state_scaffolds.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'luck_models.dart';
import 'luck_provider.dart';

/// DS §7-56: "scratch (finger-scratch mask reveal) ... skippable,
/// results also listed in history (no FOMO loss)." A literal pixel-mask
/// canvas erase is more fidelity than this scope needs -- drag distance
/// over the card fades a covering mask (0->1), which is the same
/// finger-driven reveal gesture without a custom paint layer. Skippable
/// via the button below; the outcome (once revealed) is already logged
/// to history the same as every other reward path this session.
class ScratchCardScreen extends ConsumerStatefulWidget {
  const ScratchCardScreen({super.key});

  @override
  ConsumerState<ScratchCardScreen> createState() => _ScratchCardScreenState();
}

class _ScratchCardScreenState extends ConsumerState<ScratchCardScreen> {
  double _revealProgress = 0;
  ScratchOutcome? _outcome;

  void _onPanUpdate(DragUpdateDetails details) {
    if (_outcome != null) return;
    setState(() {
      _revealProgress = (_revealProgress + details.delta.distance / 200).clamp(
        0.0,
        1.0,
      );
    });
    if (_revealProgress >= 1.0) _reveal();
  }

  void _reveal() {
    if (_outcome != null) return;
    final outcome = ref.read(luckLayerProvider.notifier).scratchCard();
    if (outcome != null) setState(() => _outcome = outcome);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final available = ref.watch(
      luckLayerProvider.select((s) => s.scratchCardsAvailable),
    );

    if (available <= 0 && _outcome == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scratch card')),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppEmptyState(
            key: const ValueKey('scratchCardEmptyState'),
            message:
                'No scratch cards yet -- earn one from a 30-day login '
                'streak or the spin wheel.',
            primaryLabel: 'Back',
            onPrimary: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Scratch card')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              key: const ValueKey('scratchCardSurface'),
              onPanUpdate: _onPanUpdate,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 240,
                    height: 160,
                    decoration: BoxDecoration(
                      color: colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.border),
                    ),
                    child: Center(
                      child: Text(
                        _outcome == null
                            ? ''
                            : switch (_outcome!.type) {
                                ScratchOutcomeType.coins =>
                                  '+${_outcome!.coins} coins',
                                ScratchOutcomeType.voucher =>
                                  _outcome!.voucherLabel!,
                                ScratchOutcomeType.blank =>
                                  'Better luck next time',
                              },
                        textAlign: TextAlign.center,
                        style: AppTypography.h2.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _outcome == null ? 1 - _revealProgress : 0,
                      duration: const Duration(milliseconds: 120),
                      child: Container(
                        key: const ValueKey('scratchCardMask'),
                        width: 240,
                        height: 160,
                        decoration: BoxDecoration(
                          color: colors.coin,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.touch_app,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _outcome == null
                  ? 'Drag across the card to scratch it'
                  : 'Result added to history',
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: const ValueKey('scratchSkipRevealButton'),
              variant: AppButtonVariant.tertiary,
              label: _outcome == null ? 'Skip (reveal instantly)' : 'Done',
              onPressed: _outcome == null
                  ? _reveal
                  : () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
