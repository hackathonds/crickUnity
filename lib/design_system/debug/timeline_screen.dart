import 'package:flutter/material.dart';

import '../components/app_ball_scrub_strip.dart';
import '../components/app_timeline.dart';
import '../icons/app_icon_id.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// QA tool for E0-08 (sub-task 6/12): [AppTimeline] (sticky date
/// separators) and [AppBallScrubStrip] (drag-to-scrub).
class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  String _scrubReadout = 'Drag the strip below';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    Widget entryCard(String text) => Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: AppTypography.body.copyWith(color: colors.textPrimary),
      ),
    );

    final entries = [
      AppTimelineEntry(
        date: yesterday,
        isKeyEvent: true,
        icon: AppIconId.trophy,
        content: entryCard('Match won vs Strikers'),
      ),
      AppTimelineEntry(date: yesterday, content: entryCard('Squad locked')),
      AppTimelineEntry(
        date: today,
        isKeyEvent: true,
        icon: AppIconId.receipt,
        content: entryCard('Expense added: Ground fee'),
      ),
      AppTimelineEntry(
        date: today,
        content: entryCard('Priya joined the team'),
      ),
      AppTimelineEntry(date: today, content: entryCard('Availability updated')),
    ];

    final balls = [
      const AppBallScrubStripEntry(
        over: 14,
        ballInOver: 1,
        outcome: AppBallOutcome.dot,
      ),
      const AppBallScrubStripEntry(
        over: 14,
        ballInOver: 2,
        outcome: AppBallOutcome.runs,
      ),
      const AppBallScrubStripEntry(
        over: 14,
        ballInOver: 3,
        outcome: AppBallOutcome.four,
      ),
      const AppBallScrubStripEntry(
        over: 14,
        ballInOver: 4,
        outcome: AppBallOutcome.wicket,
      ),
      const AppBallScrubStripEntry(
        over: 14,
        ballInOver: 5,
        outcome: AppBallOutcome.six,
      ),
      const AppBallScrubStripEntry(
        over: 14,
        ballInOver: 6,
        outcome: AppBallOutcome.extra,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Timeline & ball-scrub (QA)')),
      body: Column(
        children: [
          Expanded(
            child: AppTimeline(
              entries: entries,
              dateLabelBuilder: (date) =>
                  date.day == today.day ? 'Today' : 'Yesterday',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              _scrubReadout,
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: AppBallScrubStrip(
              balls: balls,
              onScrub: (ball) => setState(
                () => _scrubReadout =
                    'Scrubbing: ${ball.over}.${ball.ballInOver} · ${ball.outcome.name}',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
