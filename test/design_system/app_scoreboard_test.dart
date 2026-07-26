import 'package:cricunity/design_system/components/app_scoreboard.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: Scaffold(body: child),
  );

  // TV mode is a genuine 3x dimension scale meant for wide external
  // displays; real callers host it in a horizontal scroll (see
  // scoreboard_screen.dart) rather than constrain its width, so these
  // tests do the same instead of forcing it into a phone-width viewport.
  Widget tvHarness(Widget child) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: Scaffold(
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: child,
      ),
    ),
  );

  final colors = AppTheme.themes[AppTheme.defaultLight]!
      .extension<AppColors>()!;

  testWidgets('renders teams, score, overs, and context strip', (tester) async {
    await tester.pumpWidget(
      harness(
        const AppScoreboard(
          teamAShortName: 'TTN',
          teamBShortName: 'STR',
          runs: 142,
          wickets: 3,
          overs: '14.2',
          contextStrip: 'Need 47 off 34',
        ),
      ),
    );

    expect(find.text('TTN'), findsOneWidget);
    expect(find.text('STR'), findsOneWidget);
    expect(find.text('142/3'), findsOneWidget);
    expect(find.text('(14.2)'), findsOneWidget);
    expect(find.text('Need 47 off 34'), findsOneWidget);
  });

  testWidgets('the height is exactly 128 in normal mode', (tester) async {
    await tester.pumpWidget(
      harness(
        const AppScoreboard(
          teamAShortName: 'TTN',
          teamBShortName: 'STR',
          runs: 142,
          wickets: 3,
          overs: '14.2',
          contextStrip: 'Need 47 off 34',
        ),
      ),
    );

    final rect = tester.getRect(find.byKey(const ValueKey('appScoreboardBox')));
    expect(rect.height, 128);
  });

  testWidgets('the runs odometer rolls from the old value to the new one', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      harness(
        AppScoreboard(
          key: key,
          teamAShortName: 'TTN',
          teamBShortName: 'STR',
          runs: 142,
          wickets: 3,
          overs: '14.2',
          contextStrip: 'Need 47 off 34',
        ),
      ),
    );

    await tester.pumpWidget(
      harness(
        AppScoreboard(
          key: key,
          teamAShortName: 'TTN',
          teamBShortName: 'STR',
          runs: 146,
          wickets: 3,
          overs: '14.3',
          contextStrip: 'Need 43 off 33',
        ),
      ),
    );

    expect(find.text('142/3'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('146/3'), findsOneWidget);
  });

  testWidgets('a wicket flashes the underline once, in the live color', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      harness(
        AppScoreboard(
          key: key,
          teamAShortName: 'TTN',
          teamBShortName: 'STR',
          runs: 142,
          wickets: 3,
          overs: '14.2',
          contextStrip: 'Need 47 off 34',
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('appScoreboardWicketFlash')),
      findsNothing,
    );

    await tester.pumpWidget(
      harness(
        AppScoreboard(
          key: key,
          teamAShortName: 'TTN',
          teamBShortName: 'STR',
          runs: 142,
          wickets: 4,
          overs: '14.3',
          contextStrip: 'Need 47 off 33',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final flash = tester.widget<Container>(
      find.byKey(const ValueKey('appScoreboardWicketFlash')),
    );
    expect(flash.color, colors.live);

    await tester.pump(const Duration(milliseconds: 200));
    expect(
      find.byKey(const ValueKey('appScoreboardWicketFlash')),
      findsNothing,
    );
  });

  testWidgets('TV mode is 3x the height', (tester) async {
    await tester.pumpWidget(
      tvHarness(
        const AppScoreboard(
          teamAShortName: 'TTN',
          teamBShortName: 'STR',
          runs: 142,
          wickets: 3,
          overs: '14.2',
          contextStrip: 'Need 47 off 34',
          tvMode: true,
        ),
      ),
    );

    final rect = tester.getRect(find.byKey(const ValueKey('appScoreboardBox')));
    expect(rect.height, 128 * 3);
  });

  testWidgets('TV mode forces Theme 4 colors regardless of the active theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      tvHarness(
        const AppScoreboard(
          teamAShortName: 'TTN',
          teamBShortName: 'STR',
          runs: 142,
          wickets: 3,
          overs: '14.2',
          contextStrip: 'Need 47 off 34',
          tvMode: true,
        ),
      ),
    );

    final box = tester.widget<Container>(
      find.byKey(const ValueKey('appScoreboardBox')),
    );
    expect(box.color, AppColors.theme4.surface);
  });

  testWidgets(
    'TV mode with 2+ cycling strips shows the first strip initially',
    (tester) async {
      await tester.pumpWidget(
        tvHarness(
          const AppScoreboard(
            teamAShortName: 'TTN',
            teamBShortName: 'STR',
            runs: 142,
            wickets: 3,
            overs: '14.2',
            contextStrip: 'Need 47 off 34',
            tvMode: true,
            tvCyclingStrips: ['Sharma 3/28', 'Kumar 34*'],
          ),
        ),
      );

      expect(find.text('Sharma 3/28'), findsOneWidget);
    },
  );

  testWidgets('TV cycling strips rotate every 8 seconds', (tester) async {
    await tester.pumpWidget(
      tvHarness(
        const AppScoreboard(
          teamAShortName: 'TTN',
          teamBShortName: 'STR',
          runs: 142,
          wickets: 3,
          overs: '14.2',
          contextStrip: 'Need 47 off 34',
          tvMode: true,
          tvCyclingStrips: ['Sharma 3/28', 'Kumar 34*'],
        ),
      ),
    );

    expect(find.text('Sharma 3/28'), findsOneWidget);
    await tester.pump(const Duration(seconds: 8, milliseconds: 50));
    expect(find.text('Kumar 34*'), findsOneWidget);
  });

  testWidgets('non-TV mode shows contextStrip, ignoring cycling strips', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const AppScoreboard(
          teamAShortName: 'TTN',
          teamBShortName: 'STR',
          runs: 142,
          wickets: 3,
          overs: '14.2',
          contextStrip: 'Need 47 off 34',
          tvCyclingStrips: ['Sharma 3/28', 'Kumar 34*'],
        ),
      ),
    );

    expect(find.text('Need 47 off 34'), findsOneWidget);
    expect(find.text('Sharma 3/28'), findsNothing);
  });
}
