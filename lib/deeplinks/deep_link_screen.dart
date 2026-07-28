import 'package:flutter/material.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../grounds/ground_profile_screen.dart';
import '../matches/live_match_view_screen.dart';
import '../profile/profile_models.dart';
import '../profile/profile_screen.dart';
import 'deep_link_models.dart';

/// DS §1.3: "Every object screen has a canonical link ... that restores
/// exact scroll-target (e.g., link to ball 14.3 opens Scorecard
/// scrolled + highlighted)." A debug-reachable resolver rather than
/// real OS deep-link registration (no app_links package exists in this
/// project) -- demonstrates the parse-and-navigate mechanism for the
/// object types that already have a real target screen. Team/
/// Tournament/Expense/Post recognize as valid link types but have no
/// single-object-by-id screen wired yet (TeamHomeScreen needs a full
/// Team, not just an id) -- flagged rather than guessed at.
class DeepLinkScreen extends StatefulWidget {
  const DeepLinkScreen({super.key});

  @override
  State<DeepLinkScreen> createState() => _DeepLinkScreenState();
}

class _DeepLinkScreenState extends State<DeepLinkScreen> {
  final _controller = TextEditingController(
    text: 'cricunity://match/m-1/ball/14.3',
  );
  String? _error;

  static const _examples = [
    'cricunity://match/m-1/ball/14.3',
    'cricunity://ground/ground-green-valley',
    'cricunity://profile/rohan-verma',
  ];

  /// "14.3" (over 14, ball 3) -> an approximate 0-indexed position in
  /// the flat deliveries list. No PRD/DS formula is given for this
  /// conversion -- flagged approximation assuming no extras shifted the
  /// count, same convention as other unspecified-formula flags this
  /// session.
  int? _ballIndexFromOverDotBall(String? anchor) {
    if (anchor == null) return null;
    final parts = anchor.split('.');
    if (parts.length != 2) return null;
    final over = int.tryParse(parts[0]);
    final ball = int.tryParse(parts[1]);
    if (over == null || ball == null) return null;
    return over * 6 + ball - 1;
  }

  void _open() {
    final target = DeepLinkTarget.parse(_controller.text.trim());
    if (target == null) {
      setState(() => _error = 'Not a recognized cricunity:// link.');
      return;
    }
    setState(() => _error = null);

    switch (target.type) {
      case DeepLinkObjectType.match:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LiveMatchViewScreen(
              highlightBallIndex: _ballIndexFromOverDotBall(target.anchor),
            ),
          ),
        );
      case DeepLinkObjectType.ground:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GroundProfileScreen(groundId: target.objectId),
          ),
        );
      case DeepLinkObjectType.profile:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProfileScreen(
              profile: mockPlayerProfile(),
              relation: ViewerRelation.public,
            ),
          ),
        );
      case DeepLinkObjectType.team:
      case DeepLinkObjectType.tournament:
      case DeepLinkObjectType.expense:
      case DeepLinkObjectType.post:
        setState(
          () => _error =
              '${deepLinkObjectTypeLabels[target.type]} links are '
              'recognized but not wired to a screen in this pass.',
        );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('Open deep link')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const ValueKey('deepLinkInputField'),
              controller: _controller,
              decoration: const InputDecoration(labelText: 'cricunity:// link'),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              key: const ValueKey('openDeepLinkButton'),
              onPressed: _open,
              child: const Text('Open'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  _error!,
                  style: AppTypography.caption.copyWith(color: colors.error),
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Examples',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            for (final example in _examples)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: InkWell(
                  onTap: () => setState(() => _controller.text = example),
                  child: Text(
                    example,
                    style: AppTypography.body.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
