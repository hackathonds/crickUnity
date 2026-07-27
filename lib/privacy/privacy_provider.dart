import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'privacy_models.dart';

/// PRD §17: "minors get locked-stricter defaults." No PRD-given mapping
/// of exactly which surfaces get stricter -- flagged judgment call: the
/// most sensitive rows (posts, photos, messages, online status) lock to
/// the stricter end of their own allowed range for minors.
const Map<PrivacySurface, AudienceLevel> _minorStricterOverrides = {
  PrivacySurface.posts: AudienceLevel.teammatesFriends,
  PrivacySurface.photosAndTags: AudienceLevel.onlyMe,
  PrivacySurface.messagesWhoCanDm: AudienceLevel.onlyMe,
  PrivacySurface.onlineStatus: AudienceLevel.onlyMe,
};

class PrivacySettingsState {
  final Map<PrivacySurface, AudienceLevel> settings;
  final bool viewerIsMinor;

  /// PRD §17 statistics row: "ranked players' ranking stats stay public
  /// (fairness rule)." Toggleable mock -- no real ranking-eligibility
  /// check is wired to this settings screen.
  final bool viewerIsRankedPlayer;

  final AudienceLevel previewAsLevel;

  const PrivacySettingsState({
    this.settings = const {},
    this.viewerIsMinor = false,
    this.viewerIsRankedPlayer = false,
    this.previewAsLevel = AudienceLevel.everyone,
  });

  PrivacySettingsState copyWith({
    Map<PrivacySurface, AudienceLevel>? settings,
    bool? viewerIsMinor,
    bool? viewerIsRankedPlayer,
    AudienceLevel? previewAsLevel,
  }) {
    return PrivacySettingsState(
      settings: settings ?? this.settings,
      viewerIsMinor: viewerIsMinor ?? this.viewerIsMinor,
      viewerIsRankedPlayer: viewerIsRankedPlayer ?? this.viewerIsRankedPlayer,
      previewAsLevel: previewAsLevel ?? this.previewAsLevel,
    );
  }
}

class PrivacyNotifier extends Notifier<PrivacySettingsState> {
  @override
  PrivacySettingsState build() {
    return PrivacySettingsState(
      settings: {
        for (final config in privacySurfaceConfigs)
          config.surface: config.defaultLevel,
      },
    );
  }

  void setLevel(PrivacySurface surface, AudienceLevel level) {
    final config = privacySurfaceConfigs.firstWhere(
      (c) => c.surface == surface,
    );
    if (config.isHardRuleLocked) return;
    state = state.copyWith(settings: {...state.settings, surface: level});
  }

  /// PRD §17: "minors get locked-stricter defaults." Applying this
  /// resets every surface [_minorStricterOverrides] names to its locked
  /// value, on top of whatever the user had picked.
  void setViewerIsMinor(bool value) {
    final settings = {...state.settings};
    if (value) {
      settings.addAll(_minorStricterOverrides);
    } else {
      for (final config in privacySurfaceConfigs) {
        settings[config.surface] = config.defaultLevel;
      }
    }
    state = state.copyWith(viewerIsMinor: value, settings: settings);
  }

  void setViewerIsRankedPlayer(bool value) {
    state = state.copyWith(viewerIsRankedPlayer: value);
  }

  void setPreviewAsLevel(AudienceLevel level) {
    state = state.copyWith(previewAsLevel: level);
  }

  /// Whether a surface set to [PrivacySettingsState.settings]'s level is
  /// visible to a viewer at [state.previewAsLevel] -- the "previews to
  /// verify" mechanic. Lower enum index = broader audience (everyone is
  /// widest, onlyMe is narrowest), so visible iff the preview level is
  /// at least as broad as the configured minimum.
  bool visibleInPreview(PrivacySurface surface) {
    final configured = state.settings[surface];
    if (configured == null) return false;
    return state.previewAsLevel.index <= configured.index;
  }
}

final privacyProvider = NotifierProvider<PrivacyNotifier, PrivacySettingsState>(
  PrivacyNotifier.new,
);
