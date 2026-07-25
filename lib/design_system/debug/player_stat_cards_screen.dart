import 'package:flutter/material.dart';

import '../components/app_player_card.dart';
import '../components/app_statistics_card.dart';
import '../components/app_tag_chip.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// QA tool for E0-08 (sub-task 3/12): [AppPlayerCard], [AppStatisticsCard].
class PlayerStatCardsScreen extends StatefulWidget {
  const PlayerStatCardsScreen({super.key});

  @override
  State<PlayerStatCardsScreen> createState() => _PlayerStatCardsScreenState();
}

class _PlayerStatCardsScreenState extends State<PlayerStatCardsScreen> {
  bool _selected = false;

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
      appBar: AppBar(title: const Text('Player & stat cards (QA)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label('Player Card — tap to toggle selected'),
            AppPlayerCard(
              name: 'Deepak Sharma',
              roles: const ['Captain', 'Bowler'],
              teamCityLine: 'Titans · Pune',
              rating: '87',
              trend: AppRatingTrend.up,
              levelProgress: 0.6,
              selected: _selected,
              onTap: () => setState(() => _selected = !_selected),
            ),
            const SizedBox(height: AppSpacing.md),
            const AppPlayerCard(
              name: 'Priya Nair',
              roles: ['WK'],
              teamCityLine: 'Titans · Pune',
              rating: '74',
              trend: AppRatingTrend.down,
            ),
            label('Player Card — loading skeleton'),
            const AppPlayerCard(
              name: '',
              roles: [],
              teamCityLine: '',
              rating: '',
              isLoading: true,
            ),
            label('Statistics Cards — 2-up grid'),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.6,
              children: [
                AppStatisticsCard(
                  eyebrowLabel: 'Batting average',
                  value: '42.5',
                  deltaDirection: AppDeltaDirection.up,
                  deltaValue: '3.2',
                  onTap: () {},
                  onInfoTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Definition popover')),
                  ),
                ),
                AppStatisticsCard(
                  eyebrowLabel: 'Strike rate',
                  value: '118',
                  deltaDirection: AppDeltaDirection.down,
                  deltaValue: '5',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
