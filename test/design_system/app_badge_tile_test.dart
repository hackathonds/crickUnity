import 'package:cricunity/design_system/components/app_badge_tile.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: Scaffold(body: Center(child: child)),
  );

  group('AppBadgeTile', () {
    testWidgets('renders at the default grid size (88)', (tester) async {
      await tester.pumpWidget(
        harness(
          const AppBadgeTile(
            name: 'Century Club',
            color: Colors.deepOrange,
            earned: true,
          ),
        ),
      );

      final rect = tester.getRect(
        find.byKey(const ValueKey('appBadgeTileClip')),
      );
      expect(rect.width, 88);
      expect(rect.height, 88);
    });

    testWidgets('renders at the strip size (56) when given', (tester) async {
      await tester.pumpWidget(
        harness(
          const AppBadgeTile(
            name: 'Century Club',
            color: Colors.deepOrange,
            earned: true,
            size: 56,
          ),
        ),
      );

      final rect = tester.getRect(
        find.byKey(const ValueKey('appBadgeTileClip')),
      );
      expect(rect.width, 56);
    });

    testWidgets('earned shows full color and the engraved stroke', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          const AppBadgeTile(
            name: 'Century Club',
            color: Colors.deepOrange,
            earned: true,
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byKey(const ValueKey('appBadgeTileClip')),
          matching: find.byType(Container),
        ),
      );
      expect(container.color, Colors.deepOrange);
      expect(
        find.byKey(const ValueKey('appBadgeTileEngravedStroke')),
        findsOneWidget,
      );
    });

    testWidgets('locked shows a 12% silhouette and no engraved stroke', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          const AppBadgeTile(
            name: 'Hat-trick Hero',
            color: Colors.deepPurple,
            earned: false,
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byKey(const ValueKey('appBadgeTileClip')),
          matching: find.byType(Container),
        ),
      );
      expect(container.color, Colors.deepPurple.withValues(alpha: 0.12));
      expect(
        find.byKey(const ValueKey('appBadgeTileEngravedStroke')),
        findsNothing,
      );
    });

    testWidgets('the tier ribbon only renders when tierLabel is given', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          const AppBadgeTile(
            name: 'Century Club',
            color: Colors.deepOrange,
            earned: true,
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('appBadgeTileTierRibbon')),
        findsNothing,
      );

      await tester.pumpWidget(
        harness(
          const AppBadgeTile(
            name: 'Century Club',
            color: Colors.deepOrange,
            earned: true,
            tierLabel: 'Gold',
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('appBadgeTileTierRibbon')),
        findsOneWidget,
      );
      expect(find.text('Gold'), findsOneWidget);
    });

    testWidgets('tapping fires onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        harness(
          AppBadgeTile(
            name: 'Century Club',
            color: Colors.deepOrange,
            earned: true,
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('appBadgeTileClip')));
      expect(tapped, isTrue);
    });
  });

  group('AppBadgeDetailContent', () {
    testWidgets('renders name, criteria, rarity, and earn info', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          const SingleChildScrollView(
            child: AppBadgeDetailContent(
              name: 'Century Club',
              color: Colors.deepOrange,
              criteria: 'Score 100+ runs in a single innings.',
              rarityPercent: 4,
              earnDateAndProvenance: 'Earned 12 Jun 2026 · vs Strikers',
            ),
          ),
        ),
      );

      expect(find.text('Century Club'), findsOneWidget);
      expect(find.text('Score 100+ runs in a single innings.'), findsOneWidget);
      expect(find.text('Rarity: 4% of players'), findsOneWidget);
      expect(find.text('Earned 12 Jun 2026 · vs Strikers'), findsOneWidget);
    });

    testWidgets('friend avatars section only renders when given', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          const SingleChildScrollView(
            child: AppBadgeDetailContent(
              name: 'Century Club',
              color: Colors.deepOrange,
              criteria: 'Criteria',
              rarityPercent: 4,
              earnDateAndProvenance: 'Earned',
            ),
          ),
        ),
      );
      expect(find.text('Friends who hold this'), findsNothing);
    });

    testWidgets('the Share button only renders when onShare is given', (
      tester,
    ) async {
      var shared = false;
      await tester.pumpWidget(
        harness(
          SingleChildScrollView(
            child: AppBadgeDetailContent(
              name: 'Century Club',
              color: Colors.deepOrange,
              criteria: 'Criteria',
              rarityPercent: 4,
              earnDateAndProvenance: 'Earned',
              onShare: () => shared = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Share'));
      expect(shared, isTrue);
    });
  });
}
