import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_state_scaffolds.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'ground_models.dart';
import 'reviews_provider.dart';

/// DS §11.17: "Review composer (verified bookers only, post-booking
/// prompt): overall stars XL 44 targets -> facet star rows (pitch/
/// facilities/staff/value) -> photos -> text; publish -> owner-
/// notified. Non-eligible visitors see 'Reviews come from teams who've
/// played here' note (trust cue)."
class ReviewComposerScreen extends ConsumerStatefulWidget {
  final String groundId;

  const ReviewComposerScreen({super.key, required this.groundId});

  @override
  ConsumerState<ReviewComposerScreen> createState() =>
      _ReviewComposerScreenState();
}

class _ReviewComposerScreenState extends ConsumerState<ReviewComposerScreen> {
  int _overallStars = 0;
  final Map<ReviewFacet, int> _facetStars = {};
  int _photoCount = 0;
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final notifier = ref.read(reviewsProvider.notifier);
    ref.watch(reviewsProvider);
    final eligible = notifier.isEligible(widget.groundId);

    return Scaffold(
      appBar: AppBar(title: const Text('Write a review')),
      body: !eligible
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppEmptyState(
                message: "Reviews come from teams who've played here.",
                primaryLabel: 'Back to ground',
                onPrimary: () => Navigator.of(context).maybePop(),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  'Overall rating',
                  style: AppTypography.label.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                _StarRow(
                  key: const ValueKey('overallStarRow'),
                  value: _overallStars,
                  starSize: 44,
                  colors: colors,
                  onChanged: (v) => setState(() => _overallStars = v),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final facet in ReviewFacet.values) ...[
                  Text(reviewFacetLabels[facet]!, style: AppTypography.body),
                  _StarRow(
                    key: ValueKey('facetStarRow_${facet.name}'),
                    value: _facetStars[facet] ?? 0,
                    starSize: 28,
                    colors: colors,
                    onChanged: (v) => setState(() => _facetStars[facet] = v),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                const SizedBox(height: AppSpacing.md),
                // No real photo-upload pipeline exists -- a counter
                // stands in, same flagged-mock-asset convention as the
                // gallery strip (E9-02).
                Row(
                  children: [
                    Text(
                      'Photos (mock): $_photoCount',
                      style: AppTypography.body,
                    ),
                    IconButton(
                      key: const ValueKey('addReviewPhotoButton'),
                      icon: const Icon(Icons.add_a_photo_outlined),
                      onPressed: () => setState(() => _photoCount++),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  key: const ValueKey('reviewTextField'),
                  controller: _textController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Share more about your experience...',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  key: const ValueKey('publishReviewButton'),
                  variant: AppButtonVariant.primary,
                  label: 'Publish',
                  fullWidth: true,
                  onPressed: _overallStars == 0
                      ? null
                      : () {
                          notifier.submitReview(
                            groundId: widget.groundId,
                            overallStars: _overallStars,
                            facetStars: _facetStars,
                            photoCount: _photoCount,
                            text: _textController.text,
                          );
                          Navigator.of(context).pop();
                        },
                ),
              ],
            ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int value;
  final double starSize;
  final AppColors colors;
  final ValueChanged<int> onChanged;

  const _StarRow({
    super.key,
    required this.value,
    required this.starSize,
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
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: Icon(
                i <= value ? Icons.star : Icons.star_border,
                size: starSize,
                color: i <= value ? colors.coin : colors.textTertiary,
              ),
            ),
          ),
      ],
    );
  }
}
