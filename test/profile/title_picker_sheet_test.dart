import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/profile/title_picker_sheet.dart';
import 'package:cricunity/profile/titles_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const titles = [
    EquipableTitle(name: 'Iron Player'),
    EquipableTitle(name: 'Streak Master'),
    EquipableTitle(name: 'Season 4 Champion', isExpired: true),
  ];

  Widget harness({
    String? currentEquipped,
    required ValueChanged<String?> onEquip,
  }) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showTitlePickerSheet(
            context: context,
            name: 'Rohan Verma',
            titles: titles,
            currentEquipped: currentEquipped,
            onEquip: onEquip,
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  );

  testWidgets('shows the plain name as preview when nothing is equipped', (
    tester,
  ) async {
    await tester.pumpWidget(harness(onEquip: (_) {}));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Rohan Verma'), findsOneWidget);
  });

  testWidgets('tapping a title updates the live preview and calls onEquip', (
    tester,
  ) async {
    String? equipped;
    await tester.pumpWidget(harness(onEquip: (t) => equipped = t));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('titleOption_Iron Player')));
    await tester.pump();

    expect(equipped, 'Iron Player');
    expect(find.text('Rohan Verma · Iron Player'), findsOneWidget);
  });

  testWidgets('tapping None clears the equipped title', (tester) async {
    String? equipped = 'Iron Player';
    await tester.pumpWidget(
      harness(currentEquipped: 'Iron Player', onEquip: (t) => equipped = t),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('titleOption_none')));
    await tester.pump();

    expect(equipped, isNull);
    expect(find.text('Rohan Verma'), findsOneWidget);
  });

  testWidgets(
    'AC: an expired/seasonal title shows in the Archive section, not as a '
    'selectable radio option',
    (tester) async {
      await tester.pumpWidget(harness(onEquip: (_) {}));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Archive (expired)'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('titleArchived_Season 4 Champion')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('titleOption_Season 4 Champion')),
        findsNothing,
      );
    },
  );
}
