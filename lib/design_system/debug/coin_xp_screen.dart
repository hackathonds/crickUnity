import 'package:flutter/material.dart';

import '../components/app_avatar.dart';
import '../components/app_coin_chip.dart';
import '../components/app_xp_gain.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// QA tool for E0-08 (sub-task 9/12): [AppCoinChip] (earn animation,
/// odometer roll) and the XP ring-fill sweep + toast-chip.
class CoinXpScreen extends StatefulWidget {
  const CoinXpScreen({super.key});

  @override
  State<CoinXpScreen> createState() => _CoinXpScreenState();
}

class _CoinXpScreenState extends State<CoinXpScreen> {
  int _coinBalance = 240;
  double _previousXpProgress = 0.4;
  double _xpProgress = 0.4;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.sm,
        top: AppSpacing.xxl,
      ),
      child: Text(
        text,
        style: AppTypography.label.copyWith(color: colors.textTertiary),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Coin & XP widgets (QA)')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label('Coin chip — earn +25, watch the float + odometer'),
            AppCoinChip(
              balance: _coinBalance,
              onTap: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Open Wallet'))),
              onLongPress: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Last 5 transactions')),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () => setState(() => _coinBalance += 25),
              child: const Text('Earn 25 coins'),
            ),
            label('XP ring-fill sweep + toast-chip'),
            AppAvatarRingSweep(
              key: ValueKey(_xpProgress),
              size: AppAvatarSize.lg,
              name: 'Deepak Sharma',
              fromProgress: _previousXpProgress,
              toProgress: _xpProgress,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () {
                showXpGainToast(context, amount: 50);
                setState(() {
                  _previousXpProgress = _xpProgress;
                  _xpProgress = (_xpProgress + 0.2).clamp(0.0, 1.0);
                });
              },
              child: const Text('Gain +50 XP'),
            ),
          ],
        ),
      ),
    );
  }
}
