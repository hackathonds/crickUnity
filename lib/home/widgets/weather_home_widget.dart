import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/components/app_button.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../design_system/tokens/app_typography.dart';
import '../../matches/match_models.dart';
import '../../matches/matches_provider.dart';
import '../../messaging/chat_provider.dart';
import '../../social/composer_screen.dart' show composerViewerName;

/// PRD §4.13: "Forecast for my next match's ground & time (not
/// generic city): rain %, heat, 'pitch likely damp' advisory. A: View
/// hourly, Notify captain (one-tap share into team chat). V: Users
/// with upcoming outdoor events. St: Severe alert (red banner,
/// suggests reschedule flow to captains)."
///
/// No real weather API exists in this codebase (no HTTP/weather
/// package) -- forecast values are deterministically derived from the
/// ground name + date (a hash), so they genuinely vary per match
/// (ground-and-time-specific, not one static city-wide number) while
/// being an honest flagged mock rather than a real forecast.
class WeatherForecast {
  final int rainPercent;
  final int heatC;
  final bool pitchLikelyDamp;

  const WeatherForecast({
    required this.rainPercent,
    required this.heatC,
    required this.pitchLikelyDamp,
  });

  bool get isSevere => rainPercent >= 70;
}

WeatherForecast forecastFor(String groundName, DateTime date) {
  final seed =
      groundName.codeUnits.fold(0, (sum, c) => sum + c) +
      date.day +
      date.month * 31;
  final rainPercent = seed % 100;
  final heatC = 22 + (seed % 15);
  return WeatherForecast(
    rainPercent: rainPercent,
    heatC: heatC,
    pitchLikelyDamp: rainPercent > 40,
  );
}

class WeatherHomeWidgetBody extends ConsumerWidget {
  const WeatherHomeWidgetBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final now = DateTime.now();
    final nextMatch =
        ref
            .watch(matchesProvider)
            .matches
            .where(
              (m) =>
                  m.squadNames.contains(composerViewerName) &&
                  m.status == MatchStatus.accepted &&
                  m.draft.dateTime.isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.draft.dateTime.compareTo(b.draft.dateTime));

    if (nextMatch.isEmpty) {
      return Text(
        'No upcoming outdoor matches.',
        style: AppTypography.body.copyWith(color: colors.textSecondary),
      );
    }

    final match = nextMatch.first;
    final forecast = forecastFor(match.draft.groundName, match.draft.dateTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (forecast.isSevere)
          Container(
            key: const ValueKey('severeWeatherBanner'),
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Severe rain risk at ${match.draft.groundName} -- consider '
              'rescheduling.',
              style: AppTypography.caption.copyWith(color: colors.error),
            ),
          ),
        Text(
          '${match.draft.groundName} · ${forecast.rainPercent}% rain · '
          '${forecast.heatC}°C',
          style: AppTypography.body.copyWith(color: colors.textPrimary),
        ),
        if (forecast.pitchLikelyDamp)
          Text(
            'Pitch likely damp',
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            OutlinedButton(
              key: const ValueKey('viewHourlyWeatherButton'),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Hourly forecast'),
                  content: Text(
                    'Rain ${forecast.rainPercent}% · ${forecast.heatC}°C at '
                    '${match.draft.groundName}.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
              child: const Text('View hourly'),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppButton(
              key: const ValueKey('notifyCaptainButton'),
              variant: AppButtonVariant.secondary,
              label: 'Notify captain',
              onPressed: () {
                ref
                    .read(chatsProvider.notifier)
                    .sendText(
                      'chat-team',
                      'Weather heads-up for ${match.draft.groundName}: '
                          '${forecast.rainPercent}% rain, ${forecast.heatC}°C.'
                          '${forecast.isSevere ? ' Might be worth rescheduling.' : ''}',
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Shared to team chat.')),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
