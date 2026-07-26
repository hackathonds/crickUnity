import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_bottom_sheet.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_segmented_control.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'team_invite_models.dart';
import 'team_invite_provider.dart';

enum _InviteTab { qr, link, search }

/// DS §7 screen 12: "header [Invite] → sheet (QR big, link, search)."
Future<void> showTeamInviteSheet({
  required BuildContext context,
  required String teamName,
}) {
  return showAppBottomSheet<void>(
    context: context,
    title: 'Invite to $teamName',
    contentBuilder: (context) => _TeamInviteSheetContent(teamName: teamName),
  );
}

class _TeamInviteSheetContent extends StatefulWidget {
  final String teamName;

  const _TeamInviteSheetContent({required this.teamName});

  @override
  State<_TeamInviteSheetContent> createState() =>
      _TeamInviteSheetContentState();
}

class _TeamInviteSheetContentState extends State<_TeamInviteSheetContent> {
  _InviteTab _tab = _InviteTab.link;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSegmentedControl<_InviteTab>(
            key: const ValueKey('teamInviteTabControl'),
            options: _InviteTab.values,
            value: _tab,
            onChanged: (tab) => setState(() => _tab = tab),
            labelBuilder: (tab) => switch (tab) {
              _InviteTab.qr => 'QR',
              _InviteTab.link => 'Link',
              _InviteTab.search => 'Search',
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          switch (_tab) {
            _InviteTab.qr => _QrTab(teamName: widget.teamName),
            _InviteTab.link => _LinkTab(teamName: widget.teamName),
            _InviteTab.search => const _SearchTab(),
          },
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _QrTab extends StatelessWidget {
  final String teamName;

  const _QrTab({required this.teamName});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            key: const ValueKey('teamInviteQrPlaceholder'),
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.qr_code_2, size: 96, color: colors.textTertiary),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'A scannable QR image isn\'t available yet -- no QR-generation '
          'package exists in this codebase. Share the link instead.',
          style: AppTypography.caption.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.lg),
        _LinkTab(teamName: teamName),
      ],
    );
  }
}

class _LinkTab extends ConsumerWidget {
  final String teamName;

  const _LinkTab({required this.teamName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(teamInviteProvider);
    final notifier = ref.read(teamInviteProvider.notifier);
    final link = state.link;

    if (link == null || link.isExpired()) {
      return AppButton(
        key: const ValueKey('teamInviteGenerateLinkButton'),
        variant: AppButtonVariant.primary,
        label: link == null ? 'Generate invite link' : 'Generate new link',
        fullWidth: true,
        onPressed: () => notifier.generate(teamName),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: const ValueKey('teamInviteLinkText'),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            link.url,
            style: AppTypography.caption.copyWith(color: colors.textPrimary),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Expires ${link.expiresAt.day}/${link.expiresAt.month}/'
          '${link.expiresAt.year}',
          style: AppTypography.caption.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppButton(
                key: const ValueKey('teamInviteCopyLinkButton'),
                variant: AppButtonVariant.secondary,
                label: 'Copy link',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: link.url));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Link copied')));
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppButton(
                key: const ValueKey('teamInviteRevokeButton'),
                variant: AppButtonVariant.destructive,
                label: 'Revoke',
                onPressed: notifier.revoke,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SearchTab extends StatefulWidget {
  const _SearchTab();

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  final Set<String> _invited = {};

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final name in mockSuggestedPlayersToInvite)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                AppButton(
                  key: ValueKey('teamInviteSearchInvite_$name'),
                  variant: _invited.contains(name)
                      ? AppButtonVariant.secondary
                      : AppButtonVariant.primary,
                  label: _invited.contains(name) ? 'Invited' : 'Invite',
                  onPressed: _invited.contains(name)
                      ? null
                      : () => setState(() => _invited.add(name)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
