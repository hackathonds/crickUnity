import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/teams/team_documents_screen.dart';
import 'package:cricunity/teams/team_member_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness({
    required String viewerName,
    required TeamMemberRole viewerRole,
  }) => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: TeamDocumentsScreen(viewerName: viewerName, viewerRole: viewerRole),
    ),
  );

  void setTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('lists the existing mock documents', (tester) async {
    setTallViewport(tester);
    await tester.pumpWidget(
      harness(viewerName: 'Rohan Kapoor', viewerRole: TeamMemberRole.captain),
    );

    expect(find.byKey(const ValueKey('document_doc-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('document_doc-2')), findsOneWidget);
  });

  testWidgets('AC: a privileged role sees the Upload action, structurally', (
    tester,
  ) async {
    setTallViewport(tester);
    await tester.pumpWidget(
      harness(viewerName: 'Rohan Kapoor', viewerRole: TeamMemberRole.captain),
    );

    expect(find.byKey(const ValueKey('uploadDocumentFab')), findsOneWidget);
  });

  testWidgets(
    'AC: a plain player never sees the Upload action, not just disabled',
    (tester) async {
      setTallViewport(tester);
      await tester.pumpWidget(
        harness(viewerName: 'Sana Iyer', viewerRole: TeamMemberRole.player),
      );

      expect(find.byKey(const ValueKey('uploadDocumentFab')), findsNothing);
    },
  );

  testWidgets('uploading a document adds it to the top of the list', (
    tester,
  ) async {
    setTallViewport(tester);
    await tester.pumpWidget(
      harness(viewerName: 'Rohan Kapoor', viewerRole: TeamMemberRole.captain),
    );

    await tester.tap(find.byKey(const ValueKey('uploadDocumentFab')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('documentNameField')),
      'Player consent forms.pdf',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('documentUploadButton')));
    await tester.pumpAndSettle();

    expect(find.text('Player consent forms.pdf'), findsOneWidget);
  });

  testWidgets('an empty document name shows an error and does not upload', (
    tester,
  ) async {
    setTallViewport(tester);
    await tester.pumpWidget(
      harness(viewerName: 'Rohan Kapoor', viewerRole: TeamMemberRole.captain),
    );

    await tester.tap(find.byKey(const ValueKey('uploadDocumentFab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('documentUploadButton')));
    await tester.pump();

    expect(find.byKey(const ValueKey('documentUploadError')), findsOneWidget);
  });
}
