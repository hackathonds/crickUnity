import 'package:cricunity/design_system/components/app_card.dart';
import 'package:cricunity/design_system/icons/app_icon_id.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(Widget child, {AppThemeId themeId = AppThemeId.theme1}) {
    return MaterialApp(
      theme: AppTheme.themes[themeId],
      home: Scaffold(body: child),
    );
  }

  Padding cardPadding(WidgetTester tester) => tester.widget<Padding>(
    find.byKey(const ValueKey('appCardContentPadding')),
  );

  testWidgets('default padding is 16; featured switches to 20', (tester) async {
    await tester.pumpWidget(
      harness(AppCard(onTap: () {}, child: const Text('Body'))),
    );
    expect((cardPadding(tester).padding as EdgeInsets).left, 16);

    await tester.pumpWidget(
      harness(AppCard(featured: true, onTap: () {}, child: const Text('Body'))),
    );
    expect((cardPadding(tester).padding as EdgeInsets).left, 20);
  });

  testWidgets('hasMultipleActions restricts the tap target to the header', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      harness(
        AppCard(
          headerTitle: 'Title',
          hasMultipleActions: true,
          onTap: () => tapped = true,
          menuActions: [
            AppCardMenuAction(
              label: 'Share',
              icon: AppIconId.shareArc,
              onTap: () {},
            ),
          ],
          child: const Text('Body text'),
        ),
      ),
    );

    await tester.tap(find.text('Body text'), warnIfMissed: false);
    expect(tapped, isFalse);

    await tester.tap(find.text('Title'));
    expect(tapped, isTrue);
  });

  testWidgets(
    'without hasMultipleActions, tapping anywhere on the card fires onTap',
    (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        harness(
          AppCard(onTap: () => tapped = true, child: const Text('Body text')),
        ),
      );

      await tester.tap(find.text('Body text'));
      expect(tapped, isTrue);
    },
  );

  testWidgets('long-press opens the menu sheet listing every supplied action', (
    tester,
  ) async {
    var tappedAction = false;
    await tester.pumpWidget(
      harness(
        AppCard(
          headerTitle: 'Title',
          menuActions: [
            AppCardMenuAction(
              label: 'Share',
              icon: AppIconId.shareArc,
              onTap: () => tappedAction = true,
            ),
            AppCardMenuAction(
              label: 'Delete',
              icon: AppIconId.locked,
              isDestructive: true,
              onTap: () {},
            ),
          ],
          child: const Text('Body'),
        ),
      ),
    );

    await tester.longPress(find.byKey(const ValueKey('appCardSurface')));
    await tester.pumpAndSettle();

    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(tappedAction, isTrue);
  });

  testWidgets('tapping the ⋮ button opens the identical menu sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        AppCard(
          headerTitle: 'Title',
          menuActions: [
            AppCardMenuAction(
              label: 'Share',
              icon: AppIconId.shareArc,
              onTap: () {},
            ),
          ],
          child: const Text('Body'),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Share'), findsOneWidget);
  });

  testWidgets('isMoneySurface keeps a 1px border in Theme 4', (tester) async {
    await tester.pumpWidget(
      harness(
        AppCard(isMoneySurface: true, child: const Text('Money')),
        themeId: AppThemeId.theme4,
      ),
    );

    final container = tester.widget<Container>(
      find.byKey(const ValueKey('appCardSurface')),
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.border, isNotNull);
  });

  testWidgets('isLoading renders the card skeleton instead of the child', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(const AppCard(isLoading: true, child: Text('Should not show'))),
    );
    await tester.pump();

    expect(find.text('Should not show'), findsNothing);
    expect(
      find.byKey(const ValueKey('appLoadingCardSkeleton')),
      findsOneWidget,
    );
  });
}
