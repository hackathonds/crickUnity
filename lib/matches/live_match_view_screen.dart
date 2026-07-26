import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_bottom_sheet.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../offline/is_online_provider.dart';
import 'gallery_screen.dart';
import 'scorecard_screen.dart';
import 'scoring_models.dart';
import 'scoring_provider.dart';

/// DS §7 screen 28 (Live Match View, spectator): "{Scoreboard} -> tabs
/// Commentary(default)/Scorecard/Charts/Gallery; commentary auto-scroll
/// with 'Jump to live' pill when scrolled up; fan prediction chip after
/// over 2; reaction bar floats on key-moment cards. Delayed-data stamp
/// when scorer offline." Supersedes E4-08's minimal MatchViewerScreen,
/// which only ever existed as a stand-in for this screen.
///
/// Charts (DS §3.3: Manhattan/Worm/Partnerships/Wagon wheel) are
/// rendered as simplified bar/list views rather than full custom-paint
/// chart graphics -- proportionate to a debug-demo build, in the same
/// spirit as other visualization simplifications this session (e.g.
/// the field map's plain oval instead of a photorealistic ground).
/// Gallery tab reuses [GalleryBody] (E4-14) as a fan/spectator viewer
/// (never captain here -- curate actions are Match Detail/Gallery-tool
/// scope, not the spectator viewer's).
class LiveMatchViewScreen extends ConsumerStatefulWidget {
  /// PRD §7.8: "scorer quick-edit" / "scorer can add custom notes" --
  /// only ever true when the scorer themself opens this screen (a
  /// structural guard, same convention as every other privileged
  /// action this session).
  final bool isScorer;

  const LiveMatchViewScreen({super.key, this.isScorer = false});

  @override
  ConsumerState<LiveMatchViewScreen> createState() =>
      _LiveMatchViewScreenState();
}

class _LiveMatchViewScreenState extends ConsumerState<LiveMatchViewScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 4,
    vsync: this,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(inningsProvider);
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Match')),
      body: Column(
        children: [
          Container(
            key: const ValueKey('viewerScoreboardHeader'),
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: colors.surfaceAlt,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.battingTeamName,
                  style: AppTypography.subtitle.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                Text(
                  '${state.totalRuns}/${state.wicketsLost} '
                  '(${state.completedOvers}.${state.legalBallsThisOver} ov)',
                  style: AppTypography.scoreboard.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (!isOnline)
            Container(
              key: const ValueKey('delayedDataStamp'),
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              color: colors.disabledBg,
              child: Text(
                'Score paused -- scorer offline',
                style: AppTypography.caption.copyWith(color: colors.disabledFg),
              ),
            ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Commentary'),
              Tab(text: 'Scorecard'),
              Tab(text: 'Charts'),
              Tab(text: 'Gallery'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _CommentaryTab(isScorer: widget.isScorer),
                const ScorecardBody(),
                const _ChartsTab(),
                const GalleryBody(viewerName: 'Spectator', isCaptain: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentaryTab extends ConsumerStatefulWidget {
  final bool isScorer;

  const _CommentaryTab({required this.isScorer});

  @override
  ConsumerState<_CommentaryTab> createState() => _CommentaryTabState();
}

class _CommentaryTabState extends ConsumerState<_CommentaryTab> {
  final _scrollController = ScrollController();
  bool _showJumpToLive = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final atBottom =
        _scrollController.offset >=
        _scrollController.position.maxScrollExtent - 24;
    if (atBottom && _showJumpToLive) {
      setState(() => _showJumpToLive = false);
    } else if (!atBottom && !_showJumpToLive) {
      setState(() => _showJumpToLive = true);
    }
  }

  void _jumpToLive() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    ref.listen<InningsState>(inningsProvider, (previous, next) {
      final ballAdded =
          previous != null &&
          previous.deliveries.length != next.deliveries.length;
      if (ballAdded && !_showJumpToLive && _scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) _jumpToLive();
        });
      }
    });

    final state = ref.watch(inningsProvider);
    final strikerPerDelivery = state.strikerNamePerDelivery;
    final commentaryDeliveries = [
      for (var i = 0; i < state.deliveries.length; i++)
        if (!state.deliveries[i].isManualSwap) i,
    ];
    final keyMoments = keyMomentIndices(state);
    final notesByAnchor = <int, List<CommentaryNote>>{};
    for (final note in state.customNotes) {
      notesByAnchor.putIfAbsent(note.afterDeliveryIndex, () => []).add(note);
    }

    return Stack(
      children: [
        ListView(
          key: const ValueKey('commentaryList'),
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (widget.isScorer)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppButton(
                  key: const ValueKey('addCommentaryNoteButton'),
                  variant: AppButtonVariant.secondary,
                  label: 'Add note',
                  fullWidth: true,
                  onPressed: () => _showAddNoteSheet(context),
                ),
              ),
            if (state.completedOvers >= 2)
              _FanPredictionChip(key: const ValueKey('fanPredictionChip')),
            for (final note in notesByAnchor[-1] ?? const <CommentaryNote>[])
              _CustomNoteRow(note: note),
            for (final i in commentaryDeliveries) ...[
              Padding(
                key: ValueKey('commentaryEntry_$i'),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        key: keyMoments.contains(i)
                            ? ValueKey('keyMomentEntry_$i')
                            : null,
                        padding: keyMoments.contains(i)
                            ? const EdgeInsets.all(AppSpacing.sm)
                            : EdgeInsets.zero,
                        decoration: keyMoments.contains(i)
                            ? BoxDecoration(
                                color: colors.coin.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              )
                            : null,
                        child: Text(
                          commentaryFor(
                            state.deliveries[i],
                            strikerName: strikerPerDelivery[i],
                          ),
                          style: AppTypography.body.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    if (widget.isScorer)
                      IconButton(
                        key: ValueKey('editCommentaryButton_$i'),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        onPressed: () => _showEditCommentarySheet(
                          context,
                          index: i,
                          currentText: commentaryFor(
                            state.deliveries[i],
                            strikerName: strikerPerDelivery[i],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              for (final note in notesByAnchor[i] ?? const <CommentaryNote>[])
                _CustomNoteRow(note: note),
            ],
          ],
        ),
        if (_showJumpToLive)
          Positioned(
            bottom: AppSpacing.lg,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                key: const ValueKey('jumpToLivePill'),
                onTap: _jumpToLive,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Jump to live',
                    style: AppTypography.button.copyWith(color: colors.surface),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showEditCommentarySheet(
    BuildContext context, {
    required int index,
    required String currentText,
  }) {
    showAppBottomSheet<void>(
      context: context,
      title: 'Edit commentary',
      contentBuilder: (context) =>
          _EditCommentarySheetContent(index: index, currentText: currentText),
    );
  }

  void _showAddNoteSheet(BuildContext context) {
    showAppBottomSheet<void>(
      context: context,
      title: 'Add note',
      contentBuilder: (context) => const _AddNoteSheetContent(),
    );
  }
}

class _CustomNoteRow extends StatelessWidget {
  final CommentaryNote note;

  const _CustomNoteRow({required this.note});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Text(
        note.text,
        style: AppTypography.caption.copyWith(
          color: colors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _EditCommentarySheetContent extends ConsumerStatefulWidget {
  final int index;
  final String currentText;

  const _EditCommentarySheetContent({
    required this.index,
    required this.currentText,
  });

  @override
  ConsumerState<_EditCommentarySheetContent> createState() =>
      _EditCommentarySheetContentState();
}

class _EditCommentarySheetContentState
    extends ConsumerState<_EditCommentarySheetContent> {
  late final _controller = TextEditingController(text: widget.currentText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            key: const ValueKey('editCommentaryField'),
            label: 'Commentary',
            controller: _controller,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            key: const ValueKey('saveCommentaryButton'),
            variant: AppButtonVariant.primary,
            label: 'Save',
            fullWidth: true,
            onPressed: () {
              ref
                  .read(inningsProvider.notifier)
                  .editCommentary(widget.index, _controller.text.trim());
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _AddNoteSheetContent extends ConsumerStatefulWidget {
  const _AddNoteSheetContent();

  @override
  ConsumerState<_AddNoteSheetContent> createState() =>
      _AddNoteSheetContentState();
}

class _AddNoteSheetContentState extends ConsumerState<_AddNoteSheetContent> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            key: const ValueKey('addNoteField'),
            label: 'Note',
            controller: _controller,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            key: const ValueKey('submitNoteButton'),
            variant: AppButtonVariant.primary,
            label: 'Add',
            fullWidth: true,
            onPressed: () {
              final text = _controller.text.trim();
              if (text.isEmpty) return;
              ref.read(inningsProvider.notifier).addCustomNote(text);
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

const List<String> _predictionOptions = ['<150', '150-170', '170+'];

class _FanPredictionChip extends StatefulWidget {
  const _FanPredictionChip({super.key});

  @override
  State<_FanPredictionChip> createState() => _FanPredictionChipState();
}

class _FanPredictionChipState extends State<_FanPredictionChip> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Predict the final score',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final option in _predictionOptions)
                ChoiceChip(
                  key: ValueKey('predictionOption_$option'),
                  label: Text(option),
                  selected: _selected == option,
                  onSelected: (_) => setState(() => _selected = option),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartsTab extends ConsumerWidget {
  const _ChartsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(inningsProvider);
    final runsPerOver = state.runsPerOver;
    final maxOverRuns = runsPerOver.isEmpty
        ? 1
        : runsPerOver
              .map((e) => e.$1)
              .reduce((a, b) => a > b ? a : b)
              .clamp(1, 1 << 30);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'Manhattan',
          style: AppTypography.label.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          key: const ValueKey('manhattanChart'),
          height: 96,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < runsPerOver.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs / 2,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        for (var w = 0; w < runsPerOver[i].$2; w++)
                          Icon(Icons.circle, size: 6, color: colors.error),
                        Container(
                          height: 80 * runsPerOver[i].$1 / maxOverRuns,
                          color: colors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Worm (cumulative runs per over)',
          style: AppTypography.label.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            for (var i = 0; i < state.cumulativeRunsPerOver.length; i++)
              Text(
                'Ov ${i + 1}: ${state.cumulativeRunsPerOver[i]}',
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Partnerships',
          style: AppTypography.label.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < state.partnershipRuns.length; i++)
          Padding(
            key: ValueKey('partnershipRow_$i'),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Text(
              'Wicket ${i + 1}: ${state.partnershipRuns[i]} runs',
              style: AppTypography.body.copyWith(color: colors.textPrimary),
            ),
          ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Wagon wheel (shot direction breakdown)',
          style: AppTypography.label.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${state.wagonCompletionPercent.toStringAsFixed(0)}% of scoring '
          'shots logged',
          style: AppTypography.caption.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final entry in state.wagonSectorCounts.entries)
          Padding(
            key: ValueKey('wagonSectorRow_${entry.key.name}'),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Text(
              '${wagonSectorLabels[entry.key]}: ${entry.value}',
              style: AppTypography.body.copyWith(color: colors.textPrimary),
            ),
          ),
      ],
    );
  }
}
