import 'package:cricunity/design_system/components/app_comment_widget.dart';
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

  group('AppCommentComposer', () {
    testWidgets('the send button is disabled when the field is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(AppCommentComposer(authorName: 'Deepak', onSubmit: (_) {})),
      );

      final send = tester.widget<Text>(find.text('➤'));
      expect(send.style!.color, colors.disabledFg);
    });

    testWidgets('typing enables the send button', (tester) async {
      await tester.pumpWidget(
        harness(AppCommentComposer(authorName: 'Deepak', onSubmit: (_) {})),
      );

      await tester.enterText(
        find.byKey(const ValueKey('appCommentComposerInput')),
        'Nice one!',
      );
      await tester.pump();

      final send = tester.widget<Text>(find.text('➤'));
      expect(send.style!.color, colors.primary);
    });

    testWidgets('tapping send calls onSubmit and clears the field', (
      tester,
    ) async {
      String? submitted;
      await tester.pumpWidget(
        harness(
          AppCommentComposer(
            authorName: 'Deepak',
            onSubmit: (text) => submitted = text,
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('appCommentComposerInput')),
        'Nice one!',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('appCommentComposerSend')));
      await tester.pump();

      expect(submitted, 'Nice one!');
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('appCommentComposerInput')),
      );
      expect(field.controller!.text, isEmpty);
    });
  });

  group('AppCommentThread', () {
    const comments = [
      AppCommentData(
        authorName: 'Rahul',
        timeAgo: '2h',
        body: 'Great win!',
        propsCount: 4,
        replies: [
          AppCommentData(authorName: 'Priya', timeAgo: '1h', body: 'Agreed.'),
        ],
      ),
      AppCommentData(authorName: 'Simran', timeAgo: '30m', body: 'Nice.'),
    ];

    testWidgets('renders each comment row', (tester) async {
      await tester.pumpWidget(
        harness(
          const SingleChildScrollView(
            child: AppCommentThread(comments: comments),
          ),
        ),
      );

      expect(find.text('Rahul'), findsOneWidget);
      expect(find.text('Great win!'), findsOneWidget);
      expect(find.text('Props · 4'), findsOneWidget);
      expect(find.text('Simran'), findsOneWidget);
      expect(find.text('Nice.'), findsOneWidget);
    });

    testWidgets('replies are collapsed until "View N replies" is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          const SingleChildScrollView(
            child: AppCommentThread(comments: comments),
          ),
        ),
      );

      expect(find.text('View 1 replies'), findsOneWidget);
      expect(find.text('Priya'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('appCommentViewRepliesToggle')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Priya'), findsOneWidget);
      expect(find.text('Agreed.'), findsOneWidget);
      expect(find.text('Hide replies'), findsOneWidget);
    });

    testWidgets('a reply row renders the 2px rail', (tester) async {
      await tester.pumpWidget(
        harness(
          const SingleChildScrollView(
            child: AppCommentThread(comments: comments),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('appCommentViewRepliesToggle')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('appCommentReplyRail')), findsOneWidget);
    });

    testWidgets('tapping Props/Reply fires the callbacks', (tester) async {
      AppCommentData? propped;
      AppCommentData? replied;
      await tester.pumpWidget(
        harness(
          SingleChildScrollView(
            child: AppCommentThread(
              comments: comments,
              onPropsTap: (c) => propped = c,
              onReplyTap: (c) => replied = c,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Props · 4'));
      expect(propped?.authorName, 'Rahul');

      await tester.tap(find.text('Reply').first);
      expect(replied?.authorName, 'Rahul');
    });

    testWidgets('no "View replies" row when there are no replies', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          const SingleChildScrollView(
            child: AppCommentThread(
              comments: [
                AppCommentData(
                  authorName: 'Simran',
                  timeAgo: '30m',
                  body: 'Nice.',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.textContaining('replies'), findsNothing);
    });
  });
}
