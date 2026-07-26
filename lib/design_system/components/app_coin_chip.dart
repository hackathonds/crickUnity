import 'package:flutter/material.dart';

import '../icons/app_icon.dart';
import '../icons/app_icon_id.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// DS §3.15 Coin Widget: "Coin chip (app bar): 32h pill, coin icon 18 +
/// balance tnum; on earn, +N floats up 12px fading 600ms while balance
/// odometer-rolls; tap = Wallet; long-press = last-5 popover."
///
/// Stateful only to detect balance *increases* between rebuilds (to
/// trigger the earn animation) — the caller still owns the actual
/// balance value, same controlled-component pattern as everywhere else
/// in this design system.
class AppCoinChip extends StatefulWidget {
  final int balance;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AppCoinChip({
    super.key,
    required this.balance,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<AppCoinChip> createState() => AppCoinChipState();
}

class AppCoinChipState extends State<AppCoinChip>
    with SingleTickerProviderStateMixin {
  late int _displayedBalance;
  int? _earnedAmount;
  late final AnimationController _earnController;

  @override
  void initState() {
    super.initState();
    _displayedBalance = widget.balance;
    _earnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(covariant AppCoinChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.balance > oldWidget.balance) {
      setState(() {
        _earnedAmount = widget.balance - oldWidget.balance;
        _displayedBalance = oldWidget.balance;
      });
      _earnController.forward(from: 0);
    } else if (widget.balance != _displayedBalance) {
      setState(() => _displayedBalance = widget.balance);
    }
  }

  @override
  void dispose() {
    _earnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            key: const ValueKey('appCoinChipBox'),
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: AppRadius.fullRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppIcon(
                  id: AppIconId.coin,
                  semanticLabel: 'Coins',
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.xs),
                TweenAnimationBuilder<int>(
                  key: const ValueKey('appCoinChipOdometer'),
                  tween: IntTween(
                    begin: _displayedBalance,
                    end: widget.balance,
                  ),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, value, child) => Text(
                    '$value',
                    style: AppTypography.stat.copyWith(
                      fontSize: 15,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_earnedAmount != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _earnController,
                builder: (context, _) {
                  if (_earnController.isCompleted) {
                    return const SizedBox.shrink();
                  }
                  final t = _earnController.value;
                  return Opacity(
                    opacity: (1 - t).clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, -12 * t),
                      child: Center(
                        child: Text(
                          '+$_earnedAmount',
                          key: const ValueKey('appCoinChipEarnFloat'),
                          style: AppTypography.caption.copyWith(
                            color: colors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
