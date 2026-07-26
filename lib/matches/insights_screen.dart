import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'insights_models.dart';
import 'scoring_provider.dart';

enum InsightViewerRole { player, coach, guardian }

/// PRD §7.19: "Visible: team members for team insights; each player for
/// own notes ... insights on minors visible to self+coach+guardian
/// only." Read literally: per-player notes default to that player
/// alone; the minors exception is the *only* thing that opens a
/// per-player note to anyone besides its own player -- coach/guardian
/// don't get a blanket view of every teammate's notes, only minors'.
/// DS: "32. Insights ... per patterns" -- no unique anatomy, so this
/// follows the plain card-list convention used elsewhere (§68
/// Analytics' "Insights/Recommendations cards").
class InsightsScreen extends ConsumerWidget {
  final String viewerPlayerName;
  final InsightViewerRole viewerRole;

  const InsightsScreen({
    super.key,
    required this.viewerPlayerName,
    required this.viewerRole,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inningsProvider);
    final roster = {...state.battingOrder, ...state.bowlingRoster};
    final viewerFeatured = roster.contains(viewerPlayerName);
    final canSeeMinors =
        viewerRole == InsightViewerRole.coach ||
        viewerRole == InsightViewerRole.guardian;

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _InsightSection(
            key: const ValueKey('teamInsightsSection'),
            title: 'Team insights',
            notes: teamInsights(state),
          ),
          if (viewerFeatured) ...[
            const SizedBox(height: AppSpacing.xxl),
            _InsightSection(
              key: const ValueKey('myNotesSection'),
              title: 'My notes',
              notes: playerInsights(state, viewerPlayerName),
            ),
          ],
          if (canSeeMinors)
            for (final name in roster)
              if (name != viewerPlayerName && isMinorPlayer(name)) ...[
                const SizedBox(height: AppSpacing.xxl),
                _InsightSection(
                  key: ValueKey('minorNotesSection_$name'),
                  title: '$name (guardian view)',
                  notes: playerInsights(state, name),
                ),
              ],
        ],
      ),
    );
  }
}

class _InsightSection extends StatelessWidget {
  final String title;
  final List<InsightNote> notes;

  const _InsightSection({super.key, required this.title, required this.notes});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.label.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final note in notes)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              note.text,
              style: AppTypography.body.copyWith(color: colors.textPrimary),
            ),
          ),
      ],
    );
  }
}
