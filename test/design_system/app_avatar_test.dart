import 'package:cricunity/design_system/components/app_avatar.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: Scaffold(body: Center(child: child)),
  );

  final colors = AppTheme.themes[AppTheme.defaultLight]!
      .extension<AppColors>()!;

  testWidgets('derives initials from a two-word name', (tester) async {
    await tester.pumpWidget(
      harness(const AppAvatar(size: AppAvatarSize.md, name: 'Deepak Sharma')),
    );

    expect(find.text('DS'), findsOneWidget);
  });

  testWidgets('derives initials from a one-word name', (tester) async {
    await tester.pumpWidget(
      harness(const AppAvatar(size: AppAvatarSize.md, name: 'Madonna')),
    );

    expect(find.text('M'), findsOneWidget);
  });

  testWidgets('the same name always maps to the same background color', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const Row(
          children: [
            AppAvatar(size: AppAvatarSize.md, name: 'Deepak Sharma'),
            AppAvatar(size: AppAvatarSize.md, name: 'Deepak Sharma'),
          ],
        ),
      ),
    );

    final containers = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byKey(const ValueKey('appAvatarBox')),
            matching: find.byWidgetPredicate(
              (w) => w is Container && w.decoration is BoxDecoration,
            ),
          ),
        )
        .toList();
    final firstColor = (containers.first.decoration as BoxDecoration).color;
    final secondColor = (containers[1].decoration as BoxDecoration).color;
    expect(firstColor, secondColor);
  });

  testWidgets('the level ring paints at 40px+ when levelProgress is given', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const AppAvatar(
          size: AppAvatarSize.md,
          name: 'Naveen Kumar',
          levelProgress: 0.5,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('appAvatarRing')), findsOneWidget);
  });

  testWidgets('the level ring is absent below 40px even with levelProgress', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const AppAvatar(
          size: AppAvatarSize.sm,
          name: 'Naveen Kumar',
          levelProgress: 0.5,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('appAvatarRing')), findsNothing);
  });

  testWidgets('the level ring is absent when levelProgress is null', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(const AppAvatar(size: AppAvatarSize.lg, name: 'Priya Nair')),
    );

    expect(find.byKey(const ValueKey('appAvatarRing')), findsNothing);
  });

  testWidgets('verified badge renders only at 48px+ with verified: true', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const AppAvatar(
          size: AppAvatarSize.lg,
          name: 'Priya Nair',
          verified: true,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('appAvatarVerified')), findsOneWidget);
  });

  testWidgets('verified badge is absent below 48px even if verified: true', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const AppAvatar(
          size: AppAvatarSize.md,
          name: 'Priya Nair',
          verified: true,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('appAvatarVerified')), findsNothing);
  });

  testWidgets('presence dot renders success color for online', (tester) async {
    await tester.pumpWidget(
      harness(
        const AppAvatar(
          size: AppAvatarSize.lg,
          name: 'Priya Nair',
          presence: AppPresenceStatus.online,
        ),
      ),
    );

    final dotContainer = tester.widgetList<Container>(
      find.descendant(
        of: find.byKey(const ValueKey('appAvatarPresence')),
        matching: find.byType(Container),
      ),
    );
    final innerDecoration = dotContainer.last.decoration as BoxDecoration;
    expect(innerDecoration.color, colors.success);
  });

  testWidgets('presence dot renders warning color for away', (tester) async {
    await tester.pumpWidget(
      harness(
        const AppAvatar(
          size: AppAvatarSize.lg,
          name: 'Arjun Rao',
          presence: AppPresenceStatus.away,
        ),
      ),
    );

    final dotContainer = tester.widgetList<Container>(
      find.descendant(
        of: find.byKey(const ValueKey('appAvatarPresence')),
        matching: find.byType(Container),
      ),
    );
    final innerDecoration = dotContainer.last.decoration as BoxDecoration;
    expect(innerDecoration.color, colors.warning);
  });

  testWidgets('presence dot is absent when presence is null', (tester) async {
    await tester.pumpWidget(
      harness(const AppAvatar(size: AppAvatarSize.lg, name: 'Priya Nair')),
    );

    expect(find.byKey(const ValueKey('appAvatarPresence')), findsNothing);
  });

  for (final avatarSize in AppAvatarSize.values) {
    testWidgets(
      'overall footprint is exactly ${avatarSize.px}px regardless of adornments',
      (tester) async {
        await tester.pumpWidget(
          harness(
            AppAvatar(
              size: avatarSize,
              name: 'Simran Kaur',
              levelProgress: 0.5,
              presence: AppPresenceStatus.online,
              verified: true,
            ),
          ),
        );

        final rect = tester.getRect(find.byKey(const ValueKey('appAvatarBox')));
        expect(rect.width, avatarSize.px);
        expect(rect.height, avatarSize.px);
      },
    );
  }
}
