import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/guest/private_content_lock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the PRD §2.1 lock copy for the given object/owner', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themes[AppTheme.defaultLight],
        home: PrivateContentLockScreen(
          objectType: 'match',
          ownerRoleLabel: 'captain',
          onRequestAccess: () {},
        ),
      ),
    );

    expect(
      find.text('This match is private — ask the captain for access'),
      findsOneWidget,
    );
  });

  testWidgets('Request access calls onRequestAccess', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themes[AppTheme.defaultLight],
        home: PrivateContentLockScreen(
          objectType: 'match',
          ownerRoleLabel: 'captain',
          onRequestAccess: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('privateLockRequestAccess')));

    expect(tapped, isTrue);
  });
}
