import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../matches/scoring_models.dart' show keyMomentIndices, deliveryLabel;
import '../matches/scoring_provider.dart';
import '../sponsors/sponsor_provider.dart';
import 'go_live_models.dart';

enum GoLivePhase {
  preflight,
  themePicker,
  sponsorConfirm,
  countdown,
  live,
  ended,
}

class GoLiveState {
  final GoLivePhase phase;
  final PreflightChecklist checklist;
  final OverlayTheme overlayTheme;
  final bool sponsorSlotConfirmed;
  final int viewerCount;
  final StreamHealthStatus healthStatus;
  final List<LiveMoment> moments;
  final List<ChatMessage> chatMessages;
  final bool slowModeEnabled;

  const GoLiveState({
    this.phase = GoLivePhase.preflight,
    this.checklist = const PreflightChecklist(),
    this.overlayTheme = OverlayTheme.classic,
    this.sponsorSlotConfirmed = false,
    this.viewerCount = 0,
    this.healthStatus = StreamHealthStatus.healthy,
    this.moments = const [],
    this.chatMessages = const [],
    this.slowModeEnabled = false,
  });

  GoLiveState copyWith({
    GoLivePhase? phase,
    PreflightChecklist? checklist,
    OverlayTheme? overlayTheme,
    bool? sponsorSlotConfirmed,
    int? viewerCount,
    StreamHealthStatus? healthStatus,
    List<LiveMoment>? moments,
    List<ChatMessage>? chatMessages,
    bool? slowModeEnabled,
  }) {
    return GoLiveState(
      phase: phase ?? this.phase,
      checklist: checklist ?? this.checklist,
      overlayTheme: overlayTheme ?? this.overlayTheme,
      sponsorSlotConfirmed: sponsorSlotConfirmed ?? this.sponsorSlotConfirmed,
      viewerCount: viewerCount ?? this.viewerCount,
      healthStatus: healthStatus ?? this.healthStatus,
      moments: moments ?? this.moments,
      chatMessages: chatMessages ?? this.chatMessages,
      slowModeEnabled: slowModeEnabled ?? this.slowModeEnabled,
    );
  }
}

class GoLiveNotifier extends Notifier<GoLiveState> {
  final _random = Random();

  @override
  GoLiveState build() => const GoLiveState();

  void setChecklistItem({bool? orientation, bool? stability, bool? scoreSync}) {
    state = state.copyWith(
      checklist: state.checklist.copyWith(
        orientationOk: orientation,
        stabilityOk: stability,
        scoreSyncOk: scoreSync,
      ),
    );
  }

  void confirmPreflight() {
    if (!state.checklist.allOk) return;
    state = state.copyWith(phase: GoLivePhase.themePicker);
  }

  void selectOverlayTheme(OverlayTheme theme) {
    state = state.copyWith(overlayTheme: theme);
  }

  /// E15-03's sponsorProvider is now the real signal for whether this
  /// stream carries a contracted sponsor overlay (E15-01 flagged this as
  /// mock "always contracted" before Sponsor Console existed).
  void confirmThemeAndContinue() {
    final hasSponsor = ref.read(sponsorProvider).hasAcceptedStreamSponsorship;
    state = state.copyWith(
      phase: hasSponsor ? GoLivePhase.sponsorConfirm : GoLivePhase.countdown,
    );
  }

  void confirmSponsorSlot() {
    state = state.copyWith(
      sponsorSlotConfirmed: true,
      phase: GoLivePhase.countdown,
    );
  }

  void startLive() {
    state = state.copyWith(phase: GoLivePhase.live, viewerCount: 3);
  }

  void tickViewerCount() {
    if (state.phase != GoLivePhase.live) return;
    state = state.copyWith(
      viewerCount: (state.viewerCount + _random.nextInt(3) - 1).clamp(0, 999),
    );
  }

  void toggleSlowMode() {
    state = state.copyWith(slowModeEnabled: !state.slowModeEnabled);
  }

  /// "[Mark moment]" reuses the real live inningsProvider's current ball
  /// count, same reuse pattern as E14-04's Commentator room.
  void markMoment({DateTime Function() now = DateTime.now}) {
    final ballIndex = ref.read(inningsProvider).deliveries.length;
    state = state.copyWith(
      moments: [
        LiveMoment(ballIndex: ballIndex, markedAt: now()),
        ...state.moments,
      ],
    );
  }

  void endStream() {
    state = state.copyWith(phase: GoLivePhase.ended);
  }

  /// PRD: "auto-save VOD to match gallery" + DS: "VOD chaptered scrubber
  /// (innings/wicket chapter ticks)." Reuses the real keyMomentIndices
  /// (wicket/fifty/hat-trick flags) plus this stream's own marked
  /// moments rather than inventing separate chapter data.
  List<VodChapter> vodChapters() {
    final innings = ref.read(inningsProvider);
    final keyBalls = keyMomentIndices(innings);
    final chapters = <VodChapter>[
      for (final index in keyBalls)
        if (index < innings.deliveries.length)
          VodChapter(
            label: deliveryLabel(innings.deliveries[index]),
            ballIndex: index,
          ),
    ];
    chapters.sort((a, b) => a.ballIndex.compareTo(b.ballIndex));
    return chapters;
  }
}

final goLiveProvider = NotifierProvider<GoLiveNotifier, GoLiveState>(
  GoLiveNotifier.new,
);
