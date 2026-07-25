import 'package:cricunity/design_system/components/app_search_bar.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness({
    required ValueChanged<String> onSubmit,
    List<String> recentSearches = const [],
    ValueChanged<String>? onRecentTap,
    VoidCallback? onQrTap,
  }) {
    return MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: Scaffold(
        body: AppSearchBar(
          hintText: 'Search...',
          recentSearches: recentSearches,
          onSubmit: onSubmit,
          onRecentTap: onRecentTap,
          onQrTap: onQrTap,
        ),
      ),
    );
  }

  testWidgets('collapsed pill renders hint text and is 44h', (tester) async {
    await tester.pumpWidget(harness(onSubmit: (_) {}));

    expect(find.text('Search...'), findsOneWidget);
    final size = tester.getSize(find.byKey(const ValueKey('appSearchBarPill')));
    expect(size.height, 44);
  });

  testWidgets('tapping the pill opens the full-screen search UI, autofocused', (
    tester,
  ) async {
    await tester.pumpWidget(harness(onSubmit: (_) {}));

    await tester.tap(find.byKey(const ValueKey('appSearchBarPill')));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('appSearchTextField')),
    );
    expect(field.focusNode?.hasFocus, isTrue);
  });

  testWidgets('typing and submitting calls onSubmit and returns to the pill', (
    tester,
  ) async {
    String? submitted;
    await tester.pumpWidget(harness(onSubmit: (value) => submitted = value));

    await tester.tap(find.byKey(const ValueKey('appSearchBarPill')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('appSearchTextField')),
      'Titans',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(submitted, 'Titans');
    expect(find.byKey(const ValueKey('appSearchBarPill')), findsOneWidget);
  });

  testWidgets('tapping a recent search calls onRecentTap with that text', (
    tester,
  ) async {
    String? tappedRecent;
    await tester.pumpWidget(
      harness(
        onSubmit: (_) {},
        recentSearches: const ['Titans CC', 'Green Park'],
        onRecentTap: (value) => tappedRecent = value,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('appSearchBarPill')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Titans CC'));
    await tester.pumpAndSettle();

    expect(tappedRecent, 'Titans CC');
  });

  testWidgets('press-holding the mic shows the waveform; releasing hides it', (
    tester,
  ) async {
    await tester.pumpWidget(harness(onSubmit: (_) {}));

    await tester.tap(find.byKey(const ValueKey('appSearchBarPill')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('appSearchVoiceWaveform')), findsNothing);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('appSearchMicButton'))),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      find.byKey(const ValueKey('appSearchVoiceWaveform')),
      findsOneWidget,
    );

    await gesture.up();
    await tester.pump();
    expect(find.byKey(const ValueKey('appSearchVoiceWaveform')), findsNothing);
  });

  testWidgets('tapping QR calls onQrTap', (tester) async {
    var qrTapped = false;
    await tester.pumpWidget(
      harness(onSubmit: (_) {}, onQrTap: () => qrTapped = true),
    );

    await tester.tap(find.byKey(const ValueKey('appSearchBarPill')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('appSearchQrButton')));
    await tester.pump();

    expect(qrTapped, isTrue);
  });
}
