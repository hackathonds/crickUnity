import 'package:cricunity/design_system/components/app_button.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/profile/profile_models.dart';
import 'package:cricunity/profile/profile_overview_tab.dart';
import 'package:cricunity/profile/style_tag_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness({
    required ViewerRelation relation,
    List<String> styleTags = const [],
    List<WeaknessInsight> weaknesses = const [],
    ValueChanged<List<String>>? onStyleTagsChanged,
    VoidCallback? onOpenActivityCalendar,
  }) {
    final base = mockPlayerProfile();
    return MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: Scaffold(
        // Real usage (profile_screen.dart) always embeds this tab inside
        // a CustomScrollView -- match that here instead of a bare
        // Scaffold body, which has no scrollable ancestor and overflows
        // once enough sections/chips are present.
        body: SingleChildScrollView(
          child: ProfileOverviewTab(
            relation: relation,
            onStyleTagsChanged: onStyleTagsChanged,
            onOpenActivityCalendar: onOpenActivityCalendar,
            profile: PlayerProfile(
              name: base.name,
              city: base.city,
              bio: base.bio,
              roleChips: base.roleChips,
              headerStats: base.headerStats,
              recentForm: base.recentForm,
              endorsements: base.endorsements,
              styleTags: styleTags,
              weaknesses: weaknesses,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('tapping "View activity calendar" invokes the callback', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      harness(
        relation: ViewerRelation.self,
        onOpenActivityCalendar: () => opened = true,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('profileViewActivityCalendar')));
    await tester.pump();

    expect(opened, isTrue);
  });

  testWidgets('tapping an endorsement chip opens the endorser sheet, with a '
      'whistle for coach endorsers', (tester) async {
    await tester.pumpWidget(harness(relation: ViewerRelation.public));

    await tester.tap(find.text('Fielding (3)'));
    await tester.pumpAndSettle();

    expect(find.text('Arjun Rao'), findsOneWidget);
    expect(find.text('Priya Nair'), findsOneWidget);
    expect(find.text('Coach Mehta'), findsOneWidget);
    expect(find.byKey(const ValueKey('endorserCoachWhistle')), findsOneWidget);
  });

  testWidgets('self can open the style tag picker and change tags', (
    tester,
  ) async {
    List<String>? updated;
    await tester.pumpWidget(
      harness(
        relation: ViewerRelation.self,
        styleTags: const ['Anchor'],
        onStyleTagsChanged: (tags) => updated = tags,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('profileEditStyleTags')));
    await tester.pumpAndSettle();

    expect(find.text('Style tags ($maxStyleTags max)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('styleTagOption_Finisher')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('styleTagPickerDone')));
    await tester.pumpAndSettle();

    expect(updated, containsAll(['Anchor', 'Finisher']));
  });

  testWidgets('the style tag picker blocks selecting a 6th tag', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        relation: ViewerRelation.self,
        styleTags: availableStyleTags.take(maxStyleTags).toList(),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('profileEditStyleTags')));
    await tester.pumpAndSettle();

    final sixthTag = availableStyleTags[maxStyleTags];
    final button = tester.widget<AppChipActionButton>(
      find.byKey(ValueKey('styleTagOption_$sixthTag')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('a non-self viewer never has the style tag editor rendered', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(relation: ViewerRelation.teammate, styleTags: const ['Anchor']),
    );

    expect(find.text('Anchor'), findsOneWidget);
    expect(find.byKey(const ValueKey('profileEditStyleTags')), findsNothing);
  });

  testWidgets(
    'AC: the weaknesses section is structurally absent for every relation '
    'but self',
    (tester) async {
      const weaknesses = [
        WeaknessInsight(
          label: 'Left-arm spin',
          suggestedReason: '47% of dismissals to left-arm spin.',
        ),
      ];

      for (final relation in ViewerRelation.values.where(
        (r) => r != ViewerRelation.self && r != ViewerRelation.blocked,
      )) {
        await tester.pumpWidget(
          harness(relation: relation, weaknesses: weaknesses),
        );

        expect(
          find.byKey(const ValueKey('profileWeaknessesSection')),
          findsNothing,
          reason: 'weaknesses leaked for relation $relation',
        );
        expect(find.textContaining('Left-arm spin'), findsNothing);
      }
    },
  );

  testWidgets('self sees the weaknesses section', (tester) async {
    const weaknesses = [
      WeaknessInsight(
        label: 'Left-arm spin',
        suggestedReason: '47% of dismissals to left-arm spin.',
      ),
    ];

    await tester.pumpWidget(
      harness(relation: ViewerRelation.self, weaknesses: weaknesses),
    );

    expect(
      find.byKey(const ValueKey('profileWeaknessesSection')),
      findsOneWidget,
    );
    expect(find.textContaining('Left-arm spin'), findsOneWidget);
  });
}
