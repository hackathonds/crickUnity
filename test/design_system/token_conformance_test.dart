import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// E16-10 · DS §9's UI Consistency Checklist, item 1: "tokens only (no
/// raw hex)." Non-negotiable #1 (CLAUDE.md): "Raw hex... in a component
/// is a defect, not a style choice." Rather than a hand-picked sample,
/// this scans every shipped `.dart` file under `lib/` -- the full
/// surface, not a subset -- for `Color(0x...)` literals outside the
/// design-system's own token/theme files.
///
/// A short, explicitly-justified allowlist covers today's known
/// exceptions (checked by hand, one at a time, below) rather than
/// silently narrowing the scan to make it pass. Anything not on this
/// list is a real, new violation this test is meant to catch.
void main() {
  test(
    'no raw hex color literals outside token files or justified exceptions',
    () {
      final libDir = Directory('lib');
      final hexPattern = RegExp(r'Color\(0x[0-9A-Fa-f]{6,8}\)');

      // Where raw hex is the token/theme system itself defining the
      // palette -- this is what "tokens only" means callers should
      // build from, not a violation of the rule.
      const allowedDirs = ['lib/design_system/tokens', 'lib/design_system/theme'];

      // file path (posix-style, relative to repo root) -> justification.
      // Each entry was individually read and confirmed to be user/entity
      // data (not component styling) or a documented, deliberate
      // exception -- not a blanket carve-out.
      const allowedFiles = {
        // Team branding colors are per-team user data (PRD §6.1's
        // "colors" step in team creation), the same category as a
        // user's own photo -- not a component style token.
        'lib/teams/team_models.dart':
            'user-chosen team branding color, not component styling',
        'lib/teams/create_team_provider.dart':
            'user-chosen team branding color, not component styling',
        // Profile cover color is the same kind of per-user customizable
        // value (PRD §5.1's cover), not a design-system token.
        'lib/profile/profile_models.dart':
            'user-chosen profile cover color, not component styling',
        // DS §2.5: "coin is the only multicolor icon" -- the rim-shading
        // lerp target is pure black used for a shading effect derived
        // from the token color, not an arbitrary hue choice.
        'lib/design_system/icons/app_icon_glyphs_rewards.dart':
            "DS §2.5's one documented multicolor-icon exception (coin rim shading)",
        // Defensive constructor default that every real call site
        // overrides with an explicit theme color (verified: no caller
        // omits `color:`) -- never actually rendered as raw black.
        'lib/design_system/icons/app_icon.dart':
            'unused constructor-default fallback, never hit by a real caller',
      };

      final violations = <String>[];
      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final posixPath = entity.path.replaceAll('\\', '/');
        if (allowedDirs.any((d) => posixPath.contains(d))) continue;
        if (allowedFiles.keys.any((f) => posixPath.endsWith(f))) continue;

        final content = entity.readAsStringSync();
        for (final match in hexPattern.allMatches(content)) {
          violations.add('$posixPath: ${match.group(0)}');
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Raw hex color literal(s) found outside token files and the '
            'justified allowlist above -- either use a semantic AppColors '
            'token, or add a one-line justification to allowedFiles if this '
            'is genuinely user data / a documented exception:\n'
            '${violations.join('\n')}',
      );
    },
  );
}
