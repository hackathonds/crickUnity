import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_typography.dart';

/// E13-01 "tag-coverage captions": PRD/DS name no dedicated spec for
/// this beyond the backlog line itself -- read together with DS §3.3's
/// "every chart offers a table view toggle (accessibility +
/// screenshots)," the most defensible reading is an accessible caption
/// stating how much of a per-datapoint-tagged chart's data is actually
/// tagged (e.g. wagon wheel: how many scoring shots have a logged
/// sector) -- wrapped in [Semantics] so screen readers announce it
/// alongside the chart, not just sighted users reading the caption text.
class AppChartTagCoverageCaption extends StatelessWidget {
  final int tagged;
  final int total;

  const AppChartTagCoverageCaption({
    super.key,
    required this.tagged,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final percent = total == 0 ? 0 : (100 * tagged / total).round();
    final text = '$percent% of shots tagged ($tagged/$total)';
    return Semantics(
      label: text,
      child: Text(
        text,
        style: AppTypography.caption.copyWith(color: colors.textTertiary),
      ),
    );
  }
}
