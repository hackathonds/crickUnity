import 'package:cricunity/design_system/components/app_chart_shell.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: Scaffold(body: child),
  );

  Widget buildShell({
    List<String>? periods,
    int selectedPeriodIndex = 0,
    ValueChanged<int>? onPeriodChanged,
    AppChartScrubResolver? onScrub,
    List<AppChartLegendItem> legend = const [],
  }) {
    return AppChartShell(
      title: 'Runs per over',
      periods: periods,
      selectedPeriodIndex: selectedPeriodIndex,
      onPeriodChanged: onPeriodChanged,
      onScrub: onScrub,
      legend: legend,
      chart: const SizedBox.expand(key: ValueKey('demoChart')),
      tableViewBuilder: (context) => const Text('table rows here'),
    );
  }

  testWidgets('renders the title, container radius, and the chart child', (
    tester,
  ) async {
    await tester.pumpWidget(harness(buildShell()));

    expect(find.text('Runs per over'), findsOneWidget);
    expect(find.byKey(const ValueKey('demoChart')), findsOneWidget);

    final box = tester.widget<Container>(
      find.byKey(const ValueKey('appChartShellBox')),
    );
    final decoration = box.decoration as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(14));
  });

  testWidgets('omits the period control when periods is null', (tester) async {
    await tester.pumpWidget(harness(buildShell()));

    expect(
      find.byKey(const ValueKey('appSegmentedControlTrack')),
      findsNothing,
    );
  });

  testWidgets('shows the period segmented control and reports changes', (
    tester,
  ) async {
    int? changedTo;
    await tester.pumpWidget(
      harness(
        buildShell(
          periods: const ['Match', 'Season'],
          onPeriodChanged: (i) => changedTo = i,
        ),
      ),
    );

    expect(find.text('Match'), findsOneWidget);
    expect(find.text('Season'), findsOneWidget);

    await tester.tap(find.text('Season'));
    expect(changedTo, 1);
  });

  testWidgets(
    'a tap-and-hold scrub reports a value, ticks a haptic, and shows a bubble',
    (tester) async {
      var scrubCalls = 0;
      await tester.pumpWidget(
        harness(
          buildShell(
            onScrub: (fraction) {
              scrubCalls++;
              return const AppChartScrubValue('Over 3: 12');
            },
          ),
        ),
      );

      final hapticCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          hapticCalls.add(call);
          return null;
        },
      );

      expect(
        find.byKey(const ValueKey('appChartShellScrubBubble')),
        findsNothing,
      );

      final center = tester.getCenter(
        find.byKey(const ValueKey('appChartShellPlotArea')),
      );
      final gesture = await tester.startGesture(center);
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.up();

      expect(scrubCalls, greaterThan(0));
      expect(find.text('Over 3: 12'), findsOneWidget);
      expect(
        hapticCalls.any(
          (c) =>
              c.method == 'HapticFeedback.vibrate' &&
              c.arguments == 'HapticFeedbackType.selectionClick',
        ),
        isTrue,
      );

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    },
  );

  testWidgets('no scrub gesture area reacts when onScrub is null', (
    tester,
  ) async {
    await tester.pumpWidget(harness(buildShell()));

    final center = tester.getCenter(
      find.byKey(const ValueKey('appChartShellPlotArea')),
    );
    final gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.up();

    expect(
      find.byKey(const ValueKey('appChartShellScrubBubble')),
      findsNothing,
    );
  });

  testWidgets('renders a legend item per entry, omits the row when empty', (
    tester,
  ) async {
    await tester.pumpWidget(harness(buildShell()));
    expect(find.byKey(const ValueKey('appChartShellLegend')), findsNothing);

    await tester.pumpWidget(
      harness(
        buildShell(
          legend: const [
            AppChartLegendItem(color: Colors.teal, label: 'This innings'),
            AppChartLegendItem(color: Colors.amber, label: 'Last innings'),
          ],
        ),
      ),
    );

    expect(find.byKey(const ValueKey('appChartShellLegend')), findsOneWidget);
    expect(find.text('This innings'), findsOneWidget);
    expect(find.text('Last innings'), findsOneWidget);
  });

  testWidgets('the table view toggle swaps the chart for the table builder', (
    tester,
  ) async {
    await tester.pumpWidget(harness(buildShell()));

    expect(find.byKey(const ValueKey('demoChart')), findsOneWidget);
    expect(find.text('table rows here'), findsNothing);
    expect(find.text('Table view'), findsOneWidget);

    await tester.tap(find.text('Table view'));
    await tester.pump();

    expect(find.byKey(const ValueKey('demoChart')), findsNothing);
    expect(find.text('table rows here'), findsOneWidget);
    expect(find.text('Chart view'), findsOneWidget);
  });
}
