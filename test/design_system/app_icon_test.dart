import 'package:cricunity/design_system/icons/app_icon.dart';
import 'package:cricunity/design_system/icons/app_icon_id.dart';
import 'package:cricunity/design_system/icons/app_icon_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every icon id has a registered glyph', () {
    for (final id in AppIconId.values) {
      expect(appIconGlyphs.containsKey(id), isTrue, reason: 'missing: $id');
    }
  });

  test('every icon except coin has both an outline and a filled glyph', () {
    for (final id in AppIconId.values) {
      if (id == AppIconId.coin) continue;
      final glyph = appIconGlyphs[id]!;
      expect(glyph.outline, isNotNull, reason: '$id missing outline');
      expect(glyph.filled, isNotNull, reason: '$id missing filled');
      expect(
        glyph.isMulticolor,
        isFalse,
        reason: '$id should not be multicolor',
      );
    }
  });

  test('coin is the only multicolor icon', () {
    final multicolorIds = AppIconId.values.where(
      (id) => appIconGlyphs[id]!.isMulticolor,
    );
    expect(multicolorIds, [AppIconId.coin]);
    expect(appIconGlyphs[AppIconId.coin]!.multicolor, isNotNull);
    expect(appIconGlyphs[AppIconId.coin]!.outline, isNull);
    expect(appIconGlyphs[AppIconId.coin]!.filled, isNull);
  });

  testWidgets(
    'every icon builds without error, outline and filled, at every size',
    (tester) async {
      for (final id in AppIconId.values) {
        for (final active in [false, true]) {
          for (final size in [
            AppIconSize.dense,
            AppIconSize.standard,
            AppIconSize.tabBar,
          ]) {
            await tester.pumpWidget(
              Directionality(
                textDirection: TextDirection.ltr,
                child: AppIcon(
                  id: id,
                  semanticLabel: id.name,
                  active: active,
                  size: size,
                ),
              ),
            );
            expect(
              tester.takeException(),
              isNull,
              reason: '$id @ $size failed',
            );
          }
        }
      }
    },
  );

  test(
    'stroke width scales proportionally with size from the 24px reference',
    () {
      expect(resolveIconStrokeWidth(AppIconSize.standard), 1.75);
      expect(
        resolveIconStrokeWidth(AppIconSize.dense),
        closeTo(1.75 * (20 / 24), 0.0001),
      );
      expect(
        resolveIconStrokeWidth(AppIconSize.tabBar),
        closeTo(1.75 * (28 / 24), 0.0001),
      );
    },
  );

  testWidgets('semanticLabel is exposed for accessibility', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: AppIcon(id: AppIconId.home, semanticLabel: 'Home'),
      ),
    );

    expect(find.bySemanticsLabel('Home'), findsOneWidget);
  });
}
