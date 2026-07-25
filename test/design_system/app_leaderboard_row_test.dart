import 'package:cricunity/design_system/components/app_arc_ring.dart';
import 'package:cricunity/design_system/components/app_leaderboard_row.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: Scaffold(body: child),
  );

  final colors = AppTheme.themes[AppTheme.defaultLight]!
      .extension<AppColors>()!;

  const sampleData = AppLeaderboardRowData(
    rank: 5,
    name: 'Deepak Sharma',
    teamCaption: 'Titans',
    metric: '380',
  );

  group('AppLeaderboardRow', () {
    testWidgets('renders rank, name, team caption, and metric', (tester) async {
      await tester.pumpWidget(
        harness(const AppLeaderboardRow(data: sampleData)),
      );

      expect(find.text('5'), findsOneWidget);
      expect(find.text('Deepak Sharma'), findsOneWidget);
      expect(find.text('Titans'), findsOneWidget);
      expect(find.text('380'), findsOneWidget);
    });

    testWidgets('my-row styling only applies when isMe is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(const AppLeaderboardRow(data: sampleData)),
      );
      var container = tester.widget<Container>(
        find.byKey(const ValueKey('appLeaderboardRowBox')),
      );
      var decoration = container.decoration as BoxDecoration;
      expect(decoration.color, isNull);
      expect(decoration.border, isNull);

      await tester.pumpWidget(
        harness(const AppLeaderboardRow(data: sampleData, isMe: true)),
      );
      container = tester.widget<Container>(
        find.byKey(const ValueKey('appLeaderboardRowBox')),
      );
      decoration = container.decoration as BoxDecoration;
      expect(decoration.color, colors.surfaceAlt);
      final border = decoration.border as Border;
      expect(border.left.color, colors.primary);
      expect(border.left.width, 2);
    });

    testWidgets('top-3 rows get the coin-colored rank and laurel accent', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          const AppLeaderboardRow(
            data: AppLeaderboardRowData(
              rank: 2,
              name: 'Simran Kaur',
              teamCaption: 'Strikers',
              metric: '498',
            ),
          ),
        ),
      );

      final rankText = tester.widget<Text>(find.text('2'));
      expect(rankText.style!.color, colors.coin);
      expect(find.byType(AppArcRing), findsOneWidget);
    });

    testWidgets('rank 4+ has no laurel accent and a plain-ink rank', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(const AppLeaderboardRow(data: sampleData)),
      );

      final rankText = tester.widget<Text>(find.text('5'));
      expect(rankText.style!.color, colors.textPrimary);
      expect(find.byType(AppArcRing), findsNothing);
    });

    testWidgets('movement chevron matches direction color; absent when null', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(const AppLeaderboardRow(data: sampleData)),
      );
      expect(find.textContaining('▲'), findsNothing);
      expect(find.textContaining('▼'), findsNothing);

      await tester.pumpWidget(
        harness(
          const AppLeaderboardRow(
            data: AppLeaderboardRowData(
              rank: 5,
              name: 'Deepak Sharma',
              teamCaption: 'Titans',
              metric: '380',
              movement: AppLeaderboardMovement.up,
              movementValue: 2,
            ),
          ),
        ),
      );
      final up = tester.widget<Text>(find.text('▲2'));
      expect(up.style!.color, colors.success);

      await tester.pumpWidget(
        harness(
          const AppLeaderboardRow(
            data: AppLeaderboardRowData(
              rank: 5,
              name: 'Deepak Sharma',
              teamCaption: 'Titans',
              metric: '380',
              movement: AppLeaderboardMovement.down,
              movementValue: 1,
            ),
          ),
        ),
      );
      final down = tester.widget<Text>(find.text('▼1'));
      expect(down.style!.color, colors.textTertiary);
    });
  });

  group('AppLeaderboardList', () {
    final rows = [
      for (var i = 1; i <= 30; i++)
        AppLeaderboardRowData(
          rank: i,
          name: 'Player $i',
          teamCaption: 'Team $i',
          metric: '${500 - i}',
        ),
    ];

    testWidgets('renders one row per data entry', (tester) async {
      await tester.pumpWidget(
        harness(
          SizedBox(
            height: 600,
            child: AppLeaderboardList(rows: rows.sublist(0, 5)),
          ),
        ),
      );

      for (var i = 1; i <= 5; i++) {
        expect(find.text('Player $i'), findsOneWidget);
      }
    });

    testWidgets('the sticky clone is absent while "my row" is on-screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          SizedBox(
            height: 600,
            child: AppLeaderboardList(rows: rows, myIndex: 1),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('appLeaderboardStickyClone')),
        findsNothing,
      );
    });

    testWidgets('scrolling "my row" out of view shows the sticky clone', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          SizedBox(
            height: 600,
            child: AppLeaderboardList(rows: rows, myIndex: 1),
          ),
        ),
      );
      await tester.pump();

      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('appLeaderboardStickyClone')),
        findsOneWidget,
      );
    });

    testWidgets(
      'scrolling "my row" back into view hides the sticky clone again',
      (tester) async {
        await tester.pumpWidget(
          harness(
            SizedBox(
              height: 600,
              child: AppLeaderboardList(rows: rows, myIndex: 1),
            ),
          ),
        );
        await tester.pump();

        await tester.drag(find.byType(ListView), const Offset(0, -2000));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('appLeaderboardStickyClone')),
          findsOneWidget,
        );

        await tester.drag(find.byType(ListView), const Offset(0, 2000));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('appLeaderboardStickyClone')),
          findsNothing,
        );
      },
    );
  });
}
