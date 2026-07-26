import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'guest_chip.dart';
import 'guest_provider.dart';
import 'private_content_lock_screen.dart';
import 'register_sheet.dart';

/// A stand-in "public screen" -- DS §11.2's Guest mode is an overlay
/// behavior meant to apply across Live Match view, Public Profile,
/// Discover, etc., none of which exist yet (later epics). This one mock
/// screen demonstrates the whole mechanism: the persistent Guest chip,
/// blocked interactive controls each naming their action specifically
/// (this story's AC), the once-per-session auto-prompt, and the
/// private-link lock scaffold.
class GuestLiveMatchPreviewScreen extends ConsumerStatefulWidget {
  final VoidCallback onContinueWithPhone;

  const GuestLiveMatchPreviewScreen({
    super.key,
    required this.onContinueWithPhone,
  });

  @override
  ConsumerState<GuestLiveMatchPreviewScreen> createState() =>
      _GuestLiveMatchPreviewScreenState();
}

class _GuestLiveMatchPreviewScreenState
    extends ConsumerState<GuestLiveMatchPreviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final allowed = ref
          .read(guestProvider.notifier)
          .consumeAutoPromptBudget();
      if (allowed) {
        showRegisterSheet(
          context: context,
          valueLine: 'Create a free profile to follow every ball live.',
          onContinueWithPhone: widget.onContinueWithPhone,
        );
      }
    });
  }

  void _showBlocked(String valueLine) {
    showRegisterSheet(
      context: context,
      valueLine: valueLine,
      onContinueWithPhone: widget.onContinueWithPhone,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Titans vs Strikers'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: AppGuestChip(
              onSignUp: () => _showBlocked(
                'Create a free profile to get the full experience.',
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '142/3 (14.2 overs)',
              style: AppTypography.h1.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton(
                  key: const ValueKey('guestPreviewFollowButton'),
                  onPressed: () => _showBlocked(
                    'Create a free profile to follow Titans vs Strikers.',
                  ),
                  child: const Text('Follow'),
                ),
                OutlinedButton(
                  key: const ValueKey('guestPreviewReactButton'),
                  onPressed: () => _showBlocked(
                    'Create a free profile to react to this match.',
                  ),
                  child: const Text('React'),
                ),
                OutlinedButton(
                  key: const ValueKey('guestPreviewCommentButton'),
                  onPressed: () => _showBlocked(
                    'Create a free profile to comment on this match.',
                  ),
                  child: const Text('Comment'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            OutlinedButton(
              key: const ValueKey('guestPreviewPrivateMatchLink'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PrivateContentLockScreen(
                    objectType: 'match',
                    ownerRoleLabel: 'captain',
                    onRequestAccess: widget.onContinueWithPhone,
                  ),
                ),
              ),
              child: const Text('Open a private match (demo)'),
            ),
          ],
        ),
      ),
    );
  }
}
