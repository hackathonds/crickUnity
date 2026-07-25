import 'package:cricunity/design_system/components/app_match_card.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  final colors = AppTheme.themes[AppTheme.defaultLight]!
      .extension<AppColors>()!;

  group('AppMatchCard', () {
    testWidgets('renders both crest initials and the format chip', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          const AppMatchCard(
            teamAName: 'Titans',
            teamBName: 'Strikers',
            format: 'T20',
            dateGroundLine: 'Sun 7:00 AM · Green Park',
            squadLockCaption: 'Squad locks in 2h',
            statusRail: AppMatchStatusRail.lockedIn,
          ),
        ),
      );

      expect(find.text('T'), findsOneWidget); // Titans initial
      expect(find.text('S'), findsOneWidget); // Strikers initial
      expect(find.text('T20'), findsOneWidget);
    });

    testWidgets('the weather row only renders when weatherSummary is given', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          const AppMatchCard(
            teamAName: 'Titans',
            teamBName: 'Strikers',
            format: 'T20',
            dateGroundLine: 'Sun 7:00 AM · Green Park',
            squadLockCaption: 'Squad locks in 2h',
            statusRail: AppMatchStatusRail.lockedIn,
          ),
        ),
      );
      expect(find.textContaining('rain'), findsNothing);

      await tester.pumpWidget(
        harness(
          const AppMatchCard(
            teamAName: 'Titans',
            teamBName: 'Strikers',
            format: 'T20',
            dateGroundLine: 'Sun 7:00 AM · Green Park',
            weatherSummary: '10% rain',
            squadLockCaption: 'Squad locks in 2h',
            statusRail: AppMatchStatusRail.lockedIn,
          ),
        ),
      );
      expect(find.text('10% rain'), findsOneWidget);
    });

    testWidgets('the status rail color matches the given state', (
      tester,
    ) async {
      Color railColorFor(AppMatchStatusRail rail) {
        final container = tester.widget<Container>(
          find.byWidgetPredicate(
            (w) => w is Container && w.constraints?.maxWidth == 3,
          ),
        );
        return container.color!;
      }

      await tester.pumpWidget(
        harness(
          const AppMatchCard(
            teamAName: 'A',
            teamBName: 'B',
            format: 'T20',
            dateGroundLine: 'Line',
            squadLockCaption: 'Caption',
            statusRail: AppMatchStatusRail.responseNeeded,
          ),
        ),
      );
      expect(railColorFor(AppMatchStatusRail.responseNeeded), colors.warning);

      await tester.pumpWidget(
        harness(
          const AppMatchCard(
            teamAName: 'A',
            teamBName: 'B',
            format: 'T20',
            dateGroundLine: 'Line',
            squadLockCaption: 'Caption',
            statusRail: AppMatchStatusRail.cancelled,
          ),
        ),
      );
      expect(railColorFor(AppMatchStatusRail.cancelled), colors.error);
    });

    testWidgets('tapping an availability chip calls onAvailabilityChanged', (
      tester,
    ) async {
      AppAvailabilityStatus? changed;
      await tester.pumpWidget(
        harness(
          AppMatchCard(
            teamAName: 'A',
            teamBName: 'B',
            format: 'T20',
            dateGroundLine: 'Line',
            squadLockCaption: 'Caption',
            statusRail: AppMatchStatusRail.responseNeeded,
            onAvailabilityChanged: (v) => changed = v,
          ),
        ),
      );

      await tester.tap(find.text('Maybe'));
      expect(changed, AppAvailabilityStatus.maybe);
    });

    testWidgets('tapping a chip does not also fire the card-level onTap', (
      tester,
    ) async {
      var cardTapped = false;
      await tester.pumpWidget(
        harness(
          AppMatchCard(
            teamAName: 'A',
            teamBName: 'B',
            format: 'T20',
            dateGroundLine: 'Line',
            squadLockCaption: 'Caption',
            statusRail: AppMatchStatusRail.responseNeeded,
            onTap: () => cardTapped = true,
            onAvailabilityChanged: (_) {},
          ),
        ),
      );

      await tester.tap(find.text('Yes'));
      expect(cardTapped, isFalse);
    });

    testWidgets('swiping right triggers onShare', (tester) async {
      var shared = false;
      await tester.pumpWidget(
        harness(
          AppMatchCard(
            teamAName: 'A',
            teamBName: 'B',
            format: 'T20',
            dateGroundLine: 'Line',
            squadLockCaption: 'Caption',
            statusRail: AppMatchStatusRail.responseNeeded,
            onShare: () => shared = true,
            onPin: () {},
          ),
        ),
      );

      // A drag this large clamps to 100% of whatever width the row
      // resolves to internally (LayoutBuilder's constraints.maxWidth,
      // which can exceed the card's own shrink-wrapped visual width) --
      // safely past the 40% commit threshold regardless.
      final content = find.byKey(const ValueKey('appSwipeActionRowContent'));
      final gesture = await tester.startGesture(tester.getCenter(content));
      await gesture.moveBy(const Offset(2000, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 200));

      expect(shared, isTrue);
    });

    testWidgets('swiping left triggers onPin', (tester) async {
      var pinned = false;
      await tester.pumpWidget(
        harness(
          AppMatchCard(
            teamAName: 'A',
            teamBName: 'B',
            format: 'T20',
            dateGroundLine: 'Line',
            squadLockCaption: 'Caption',
            statusRail: AppMatchStatusRail.responseNeeded,
            onShare: () {},
            onPin: () => pinned = true,
          ),
        ),
      );

      final content = find.byKey(const ValueKey('appSwipeActionRowContent'));
      final gesture = await tester.startGesture(tester.getCenter(content));
      await gesture.moveBy(const Offset(-2000, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 200));

      expect(pinned, isTrue);
    });
  });

  group('AppLiveMatchCard', () {
    testWidgets('renders the score and chasing lines', (tester) async {
      await tester.pumpWidget(
        harness(
          const AppLiveMatchCard(
            teamAName: 'Titans',
            teamBName: 'Strikers',
            scoreLine: '142/3 (14.2)',
            chasingLine: 'Need 47 off 34',
          ),
        ),
      );

      expect(find.text('142/3 (14.2)'), findsOneWidget);
      expect(find.text('Need 47 off 34'), findsOneWidget);
    });

    testWidgets('tapping fires onTap; long-pressing fires onMute', (
      tester,
    ) async {
      var tapped = false;
      var muted = false;
      await tester.pumpWidget(
        harness(
          AppLiveMatchCard(
            teamAName: 'Titans',
            teamBName: 'Strikers',
            scoreLine: '142/3 (14.2)',
            onTap: () => tapped = true,
            onMute: () => muted = true,
          ),
        ),
      );

      await tester.tap(find.text('142/3 (14.2)'));
      expect(tapped, isTrue);

      await tester.longPress(find.text('142/3 (14.2)'));
      expect(muted, isTrue);
    });

    testWidgets('the key-moment chip appears only when keyMoment is set', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          const AppLiveMatchCard(
            teamAName: 'Titans',
            teamBName: 'Strikers',
            scoreLine: '142/3 (14.2)',
          ),
        ),
      );
      expect(find.text('WICKET · Sharma 34'), findsNothing);

      await tester.pumpWidget(
        harness(
          const AppLiveMatchCard(
            teamAName: 'Titans',
            teamBName: 'Strikers',
            scoreLine: '142/3 (14.2)',
            keyMoment: 'WICKET · Sharma 34',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('WICKET · Sharma 34'), findsOneWidget);
    });
  });

  group('AppTournamentCard', () {
    testWidgets('the sanctioned chip only renders when sanctioned is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          const AppTournamentCard(
            name: 'City Cup',
            teamsCountDatesEntryFeeLine: '8 teams · 5-6 Sep · ₹1,000',
          ),
        ),
      );
      expect(find.text('Sanctioned'), findsNothing);

      await tester.pumpWidget(
        harness(
          const AppTournamentCard(
            name: 'City Cup',
            sanctioned: true,
            teamsCountDatesEntryFeeLine: '8 teams · 5-6 Sep · ₹1,000',
          ),
        ),
      );
      expect(find.text('Sanctioned'), findsOneWidget);
    });

    testWidgets('shows the my-team position pill when provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          const AppTournamentCard(
            name: 'City Cup',
            teamsCountDatesEntryFeeLine: '8 teams · 5-6 Sep · ₹1,000',
            myTeamPosition: '3rd of 8',
          ),
        ),
      );

      expect(find.text('3rd of 8'), findsOneWidget);
      expect(find.textContaining('Register'), findsNothing);
    });

    testWidgets('shows the Register CTA when no position is given', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          const AppTournamentCard(
            name: 'City Cup',
            teamsCountDatesEntryFeeLine: '8 teams · 5-6 Sep · ₹1,000',
          ),
        ),
      );

      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets(
      'the footer tints warning when registration closes within 48h',
      (tester) async {
        await tester.pumpWidget(
          harness(
            AppTournamentCard(
              name: 'City Cup',
              teamsCountDatesEntryFeeLine: '8 teams · 5-6 Sep · ₹1,000',
              registrationCloses: DateTime.now().add(const Duration(hours: 10)),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.byWidgetPredicate(
            (w) =>
                w is Container &&
                (w.decoration as BoxDecoration?)?.color ==
                    colors.warning.withValues(alpha: 0.12),
          ),
        );
        expect(container, isNotNull);
      },
    );
  });
}
