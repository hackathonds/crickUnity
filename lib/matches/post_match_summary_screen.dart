import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_money_text.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../social/feed_models.dart';
import '../social/feed_provider.dart';
import '../teams/peer_rating_models.dart';
import '../teams/peer_rating_sheet.dart';
import 'awards_screen.dart';
import 'ball_timeline_screen.dart';
import 'insights_models.dart';
import 'insights_screen.dart';
import 'scoring_provider.dart';

/// No 2-innings match model exists yet, so there's no real second
/// score to compare against -- a mock opponent total stands in so a
/// genuine result (winner + margin) can be computed and displayed.
const int _mockOpponentTeamRuns = 142;

/// DS §7 screen 30 (Post-Match Summary): "Result hero (winner crest +
/// margin Clash 22) -> MVP card -> my performance card [Share] -> XP/
/// coins earned strip -> expense card '₹283 - [Pay]' -> rate-players
/// entry (window countdown) -> insights teaser -> timeline link. Order
/// enforces Pillar: ceremony visible, obligation adjacent." AC:
/// "ceremony and obligation share first viewport" -- the result hero
/// and expense card are kept close together with compact cards between
/// them, though literal viewport-fit on a real device needs the manual
/// screenshot QA this environment can't perform.
class PostMatchSummaryScreen extends ConsumerWidget {
  final String viewerPlayerName;

  const PostMatchSummaryScreen({super.key, required this.viewerPlayerName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(inningsProvider);

    final battingTeamWon = state.totalRuns > _mockOpponentTeamRuns;
    final tied = state.totalRuns == _mockOpponentTeamRuns;
    final resultText = tied
        ? 'Match tied'
        : battingTeamWon
        ? '${state.battingTeamName} won by '
              '${state.totalRuns - _mockOpponentTeamRuns} runs'
        : '${state.bowlingTeamName} won by '
              '${10 - state.wicketsLost} wickets';

    final myBatting = state.batters[viewerPlayerName];
    final myBowling = state.bowlers[viewerPlayerName];

    final ratingsWindow = peerRatingWindowFor(state.scorecardPostedAt);
    final ratingsWindowOpensAt = ratingsWindow.opensAt;
    final ratingsWindowClosesAt = ratingsWindow.closesAt;
    final myTeamRoster = state.battingOrder.contains(viewerPlayerName)
        ? state.battingOrder
        : state.bowlingRoster;
    final teammates = myTeamRoster
        .where((name) => name != viewerPlayerName)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Match summary')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // 1. Result hero (ceremony).
          Text(
            key: const ValueKey('resultHero'),
            resultText,
            style: AppTypography.h1.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.lg),
          // 2. MVP card.
          _SummaryCard(
            key: const ValueKey('mvpCard'),
            title: 'MVP',
            body: state.mvpIsCaptainPick
                ? '${state.finalMvp} (picked by opposing captain)'
                : '${state.finalMvp} (auto-suggested)',
            trailing: AppButton(
              key: const ValueKey('viewAwardsButton'),
              variant: AppButtonVariant.tertiary,
              label: 'Awards',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AwardsScreen(isOpposingCaptain: false),
                ),
              ),
            ),
          ),
          // 3. My performance card [Share].
          _SummaryCard(
            key: const ValueKey('myPerformanceCard'),
            title: 'My performance',
            body: myBatting == null && myBowling == null
                ? "Didn't feature in this innings."
                : [
                    if (myBatting != null)
                      '${myBatting.runs} (${myBatting.balls})',
                    if (myBowling != null)
                      '${myBowling.completedOvers}.'
                          '${myBowling.ballsThisOver}-'
                          '${myBowling.runsConceded}-${myBowling.wickets}',
                  ].join(' · '),
            trailing: _SharePerformanceButton(
              viewerPlayerName: viewerPlayerName,
              resultText: resultText,
            ),
          ),
          // 4. XP/coins earned strip.
          Container(
            key: const ValueKey('xpCoinsStrip'),
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.coin.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              state.rippleFired
                  ? 'Earned this match: 25 coins · 40 XP'
                  : 'Coins/XP release once the scorecard is fully confirmed.',
              style: AppTypography.body.copyWith(color: colors.textPrimary),
            ),
          ),
          // 5. Expense card (obligation).
          Container(
            key: const ValueKey('expenseCard'),
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const AppMoneyText(symbol: '₹', amount: '173'),
                const Spacer(),
                AppButton(
                  key: const ValueKey('payExpenseButton'),
                  variant: AppButtonVariant.primary,
                  label: 'Pay',
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Payment recorded (mock -- no Treasury module yet)',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 6. Rate-players entry.
          _SummaryCard(
            key: const ValueKey('ratePlayersCard'),
            title: 'Rate your teammates',
            body:
                'Window: ${ratingsWindowOpensAt.day}/'
                '${ratingsWindowOpensAt.month} - '
                '${ratingsWindowClosesAt.day}/${ratingsWindowClosesAt.month}',
            trailing: AppButton(
              key: const ValueKey('ratePlayersButton'),
              variant: AppButtonVariant.secondary,
              label: 'Rate',
              onPressed: () => showPeerRatingSheet(
                context: context,
                raterName: viewerPlayerName,
                teammates: teammates,
                window: ratingsWindow,
              ),
            ),
          ),
          // 7. Insights teaser.
          _SummaryCard(
            key: const ValueKey('insightsTeaserCard'),
            title: 'Insights',
            body: teamInsights(state).first.text,
            trailing: AppButton(
              key: const ValueKey('viewInsightsButton'),
              variant: AppButtonVariant.tertiary,
              label: 'View insights',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => InsightsScreen(
                    viewerPlayerName: viewerPlayerName,
                    viewerRole: InsightViewerRole.player,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // 8. Timeline link.
          AppButton(
            key: const ValueKey('viewTimelineButton'),
            variant: AppButtonVariant.tertiary,
            label: 'View match timeline',
            fullWidth: true,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BallTimelineScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

/// DS §1.5 "Post match performance card": budget 2, "Share -> Post."
/// Share only ever copied the card to the clipboard with no second step
/// -- this makes the second tap real: posting to the feed via the same
/// [FeedNotifier.addPost] hook E17-01's Match Ripple already uses for
/// the match-summary post.
class _SharePerformanceButton extends ConsumerStatefulWidget {
  final String viewerPlayerName;
  final String resultText;

  const _SharePerformanceButton({
    required this.viewerPlayerName,
    required this.resultText,
  });

  @override
  ConsumerState<_SharePerformanceButton> createState() =>
      _SharePerformanceButtonState();
}

class _SharePerformanceButtonState
    extends ConsumerState<_SharePerformanceButton> {
  bool _shared = false;
  bool _posted = false;

  @override
  Widget build(BuildContext context) {
    if (_posted) {
      return const Icon(Icons.check_circle_outline, size: 20);
    }
    return AppButton(
      key: ValueKey(
        _shared ? 'postPerformanceButton' : 'sharePerformanceButton',
      ),
      variant: _shared ? AppButtonVariant.primary : AppButtonVariant.secondary,
      label: _shared ? 'Post' : 'Share',
      onPressed: _shared ? _post : _share,
    );
  }

  void _share() {
    Clipboard.setData(
      ClipboardData(text: '${widget.viewerPlayerName} -- ${widget.resultText}'),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Performance card copied')));
    setState(() => _shared = true);
  }

  void _post() {
    ref
        .read(feedProvider.notifier)
        .addPost(
          FeedPost(
            id: 'post-perf-${DateTime.now().microsecondsSinceEpoch}',
            authorName: widget.viewerPlayerName,
            contentText: '${widget.viewerPlayerName} -- ${widget.resultText}',
            timestamp: DateTime.now(),
            isFollowed: true,
            relationshipScore: 1.0,
            cricketRelevanceScore: 1.0,
            audience: PostAudience.public,
          ),
        );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Posted to your feed')));
    setState(() => _posted = true);
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String body;
  final Widget? trailing;

  const _SummaryCard({
    super.key,
    required this.title,
    required this.body,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.label.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
                Text(
                  body,
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
