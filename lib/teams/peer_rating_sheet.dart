import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'peer_rating_models.dart';
import 'peer_rating_provider.dart';

/// DS §11.6: "Peer-rating sheet (post-match, window countdown): teammate
/// rows with 5-star tap targets 44 + optional tag chips; anonymity note
/// pinned top; submit-all sticky." PRD §6.27's anti-identification rule
/// means this sheet never reveals another rater's ballot -- only whether
/// *this* rater has already submitted.
Future<void> showPeerRatingSheet({
  required BuildContext context,
  required String raterName,
  required List<String> teammates,
  required PeerRatingWindow window,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _PeerRatingSheetContent(
      raterName: raterName,
      teammates: teammates,
      window: window,
    ),
  );
}

class _PeerRatingSheetContent extends ConsumerStatefulWidget {
  final String raterName;
  final List<String> teammates;
  final PeerRatingWindow window;

  const _PeerRatingSheetContent({
    required this.raterName,
    required this.teammates,
    required this.window,
  });

  @override
  ConsumerState<_PeerRatingSheetContent> createState() =>
      _PeerRatingSheetContentState();
}

class _PeerRatingSheetContentState
    extends ConsumerState<_PeerRatingSheetContent> {
  final Map<String, int> _stars = {};
  final Map<String, Set<String>> _tags = {};

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final now = DateTime.now();
    // Watched (not just read) so the sheet flips to the submitted state the
    // instant this rater's ballot lands in state.
    ref.watch(peerRatingsProvider);
    final notifier = ref.read(peerRatingsProvider.notifier);
    final alreadySubmitted = notifier.hasSubmitted(widget.raterName);

    final interactive = widget.window.isOpenAt(now) && !alreadySubmitted;

    // DS §3.5's 92%-detent cap, so this never overflows regardless of
    // roster size -- rows scroll, the submit button stays sticky below.
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rate your teammates',
              key: const ValueKey('peerRatingSheetTitle'),
              style: AppTypography.title.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Anonymous -- no teammate ever sees who rated them.',
              key: const ValueKey('peerRatingAnonymityNote'),
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (widget.window.hasClosedAt(now))
              _StatusMessage(
                key: const ValueKey('peerRatingWindowClosed'),
                text: 'The rating window for this match has closed.',
              )
            else if (!widget.window.isOpenAt(now))
              _StatusMessage(
                key: const ValueKey('peerRatingWindowNotOpen'),
                text:
                    'Ratings open ${_hoursUntil(widget.window.opensAt, now)}h '
                    'from now, once the scorecard has settled.',
              )
            else if (alreadySubmitted)
              const _StatusMessage(
                key: ValueKey('peerRatingAlreadySubmitted'),
                text: "Thanks -- your ratings are recorded for this match.",
              ),
            if (interactive) ...[
              Expanded(
                child: ListView(
                  children: [
                    for (final teammate in widget.teammates)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: _TeammateRatingRow(
                          key: ValueKey('peerRatingRow_$teammate'),
                          teammateName: teammate,
                          stars: _stars[teammate] ?? 0,
                          selectedTags: _tags[teammate] ?? const {},
                          onStarsChanged: (v) =>
                              setState(() => _stars[teammate] = v),
                          onTagToggled: (tag) => setState(() {
                            final set = _tags.putIfAbsent(teammate, () => {});
                            if (!set.remove(tag)) set.add(tag);
                          }),
                        ),
                      ),
                  ],
                ),
              ),
              AppButton(
                key: const ValueKey('submitPeerRatingsButton'),
                variant: AppButtonVariant.primary,
                label: 'Submit ratings',
                fullWidth: true,
                onPressed: _stars.values.any((v) => v > 0)
                    ? () {
                        notifier.submitAll(
                          raterName: widget.raterName,
                          starsByTeammate: {
                            for (final e in _stars.entries)
                              if (e.value > 0) e.key: e.value,
                          },
                          tagsByTeammate: {
                            for (final e in _tags.entries)
                              if (e.value.isNotEmpty) e.key: e.value.toList(),
                          },
                        );
                        setState(() {});
                      }
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _hoursUntil(DateTime target, DateTime now) =>
      target.difference(now).inHours.clamp(0, 1 << 30);
}

class _StatusMessage extends StatelessWidget {
  final String text;

  const _StatusMessage({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Text(
        text,
        style: AppTypography.body.copyWith(color: colors.textSecondary),
      ),
    );
  }
}

class _TeammateRatingRow extends StatelessWidget {
  final String teammateName;
  final int stars;
  final Set<String> selectedTags;
  final ValueChanged<int> onStarsChanged;
  final ValueChanged<String> onTagToggled;

  const _TeammateRatingRow({
    super.key,
    required this.teammateName,
    required this.stars,
    required this.selectedTags,
    required this.onStarsChanged,
    required this.onTagToggled,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          teammateName,
          style: AppTypography.subtitle.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        _StarRow(value: stars, colors: colors, onChanged: onStarsChanged),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final tag in peerRatingTags)
              AppChipActionButton(
                key: ValueKey('peerRatingTag_${teammateName}_$tag'),
                label: tag,
                selected: selectedTags.contains(tag),
                onPressed: () => onTagToggled(tag),
              ),
          ],
        ),
      ],
    );
  }
}

/// 44px tap-target stars, same shape as [ReviewComposerScreen]'s overall
/// star row (`lib/grounds/review_composer_screen.dart`) -- private to each
/// caller rather than a shared component, matching that precedent.
class _StarRow extends StatelessWidget {
  final int value;
  final AppColors colors;
  final ValueChanged<int> onChanged;

  const _StarRow({
    required this.value,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= 5; i++)
          GestureDetector(
            key: ValueKey('star_$i'),
            onTap: () => onChanged(i),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                i <= value ? Icons.star : Icons.star_border,
                size: 28,
                color: i <= value ? colors.coin : colors.textTertiary,
              ),
            ),
          ),
      ],
    );
  }
}
