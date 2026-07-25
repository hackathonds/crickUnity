import 'package:cricunity/design_system/components/app_player_card.dart';
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

  testWidgets('renders name, role chips, team/city line, and rating', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const AppPlayerCard(
          name: 'Deepak Sharma',
          roles: ['Captain', 'Bowler'],
          teamCityLine: 'Titans · Pune',
          rating: '87',
        ),
      ),
    );

    expect(find.text('Deepak Sharma'), findsOneWidget);
    expect(find.text('Captain'), findsOneWidget);
    expect(find.text('Bowler'), findsOneWidget);
    expect(find.text('Titans · Pune'), findsOneWidget);
    expect(find.text('87'), findsOneWidget);
  });

  testWidgets('no border when not selected', (tester) async {
    await tester.pumpWidget(
      harness(
        const AppPlayerCard(
          name: 'Deepak Sharma',
          roles: [],
          teamCityLine: 'Titans · Pune',
          rating: '87',
        ),
      ),
    );

    final box = tester.widget<Container>(
      find.byKey(const ValueKey('appPlayerCardBox')),
    );
    final decoration = box.decoration as BoxDecoration;
    expect(decoration.border, isNull);
  });

  testWidgets('1.5px primary border and check badge when selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const AppPlayerCard(
          name: 'Deepak Sharma',
          roles: [],
          teamCityLine: 'Titans · Pune',
          rating: '87',
          selected: true,
        ),
      ),
    );

    final box = tester.widget<Container>(
      find.byKey(const ValueKey('appPlayerCardBox')),
    );
    final decoration = box.decoration as BoxDecoration;
    expect(decoration.border!.top.color, colors.primary);
    expect(decoration.border!.top.width, 1.5);
  });

  testWidgets('the trend arrow renders success color for up', (tester) async {
    await tester.pumpWidget(
      harness(
        const AppPlayerCard(
          name: 'Deepak Sharma',
          roles: [],
          teamCityLine: 'Titans · Pune',
          rating: '87',
          trend: AppRatingTrend.up,
        ),
      ),
    );

    final arrow = tester.widget<Text>(find.text('▲'));
    expect(arrow.style!.color, colors.success);
  });

  testWidgets('the trend arrow renders textTertiary (neutral) for down', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const AppPlayerCard(
          name: 'Deepak Sharma',
          roles: [],
          teamCityLine: 'Titans · Pune',
          rating: '87',
          trend: AppRatingTrend.down,
        ),
      ),
    );

    final arrow = tester.widget<Text>(find.text('▼'));
    expect(arrow.style!.color, colors.textTertiary);
  });

  testWidgets('tapping the card fires onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      harness(
        AppPlayerCard(
          name: 'Deepak Sharma',
          roles: const [],
          teamCityLine: 'Titans · Pune',
          rating: '87',
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.text('Deepak Sharma'));
    expect(tapped, isTrue);
  });

  testWidgets('isLoading renders the skeleton instead of content', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const AppPlayerCard(
          name: 'Deepak Sharma',
          roles: [],
          teamCityLine: 'Titans · Pune',
          rating: '87',
          isLoading: true,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('appPlayerCardSkeleton')), findsOneWidget);
    expect(find.text('Deepak Sharma'), findsNothing);
  });
}
