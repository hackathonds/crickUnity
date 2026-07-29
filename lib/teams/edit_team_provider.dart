import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'team_models.dart';

/// PRD §6.2: "'Formerly known as…' for 90 days."
const int formerNameWindowDays = 90;

/// The saved (server-side, in this mocked world) form of the team --
/// what [EditTeamState.isDirty] compares in-progress edits against. Same
/// baseline/dirty-tracking shape as `EditProfileProvider` (E2-02).
class EditTeamBaseline {
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final String city;
  final String homeGround;
  final Set<TeamFormat> formatFocus;
  final TeamJoinPolicy joinPolicy;
  final List<TeamIdentityChangeLogEntry> changeLog;
  final String? formerName;
  final DateTime? formerNameExpiresAt;

  const EditTeamBaseline({
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.city,
    this.homeGround = '',
    this.formatFocus = const {},
    this.joinPolicy = TeamJoinPolicy.open,
    this.changeLog = const [],
    this.formerName,
    this.formerNameExpiresAt,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'primaryColor': primaryColor.toARGB32(),
    'secondaryColor': secondaryColor.toARGB32(),
    'city': city,
    'homeGround': homeGround,
    'formatFocus': formatFocus.map((f) => f.name).toList(),
    'joinPolicy': joinPolicy.name,
    'changeLog': changeLog.map((e) => e.toJson()).toList(),
    'formerName': formerName,
    'formerNameExpiresAt': formerNameExpiresAt?.toIso8601String(),
  };

  factory EditTeamBaseline.fromJson(Map<String, dynamic> json) {
    return EditTeamBaseline(
      name: json['name'] as String,
      primaryColor: Color(json['primaryColor'] as int),
      secondaryColor: Color(json['secondaryColor'] as int),
      city: json['city'] as String,
      homeGround: json['homeGround'] as String? ?? '',
      formatFocus: {
        for (final f in (json['formatFocus'] as List? ?? const []))
          TeamFormat.values.byName(f as String),
      },
      joinPolicy: TeamJoinPolicy.values.byName(
        json['joinPolicy'] as String? ?? TeamJoinPolicy.open.name,
      ),
      changeLog: [
        for (final e in (json['changeLog'] as List? ?? const []))
          TeamIdentityChangeLogEntry.fromJson(e as Map<String, dynamic>),
      ],
      formerName: json['formerName'] as String?,
      formerNameExpiresAt: (json['formerNameExpiresAt'] as String?) == null
          ? null
          : DateTime.parse(json['formerNameExpiresAt'] as String),
    );
  }
}

class EditTeamState {
  final EditTeamBaseline baseline;
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final String city;
  final String homeGround;
  final Set<TeamFormat> formatFocus;
  final TeamJoinPolicy joinPolicy;
  final bool saved;

  const EditTeamState({
    required this.baseline,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.city,
    required this.homeGround,
    required this.formatFocus,
    required this.joinPolicy,
    this.saved = false,
  });

  bool get nameChanged => name.trim() != baseline.name;

  bool get isDirty =>
      name.trim() != baseline.name ||
      primaryColor != baseline.primaryColor ||
      secondaryColor != baseline.secondaryColor ||
      city.trim() != baseline.city ||
      homeGround.trim() != baseline.homeGround ||
      !_setEquals(formatFocus, baseline.formatFocus) ||
      joinPolicy != baseline.joinPolicy;

  bool get canSave =>
      isDirty &&
      name.trim().length >= 3 &&
      city.trim().isNotEmpty &&
      formatFocus.isNotEmpty;

  bool formerNameActive({DateTime Function() now = DateTime.now}) =>
      baseline.formerName != null &&
      baseline.formerNameExpiresAt != null &&
      now().isBefore(baseline.formerNameExpiresAt!);

  EditTeamState copyWith({
    String? name,
    Color? primaryColor,
    Color? secondaryColor,
    String? city,
    String? homeGround,
    Set<TeamFormat>? formatFocus,
    TeamJoinPolicy? joinPolicy,
    bool? saved,
  }) {
    return EditTeamState(
      baseline: baseline,
      name: name ?? this.name,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      city: city ?? this.city,
      homeGround: homeGround ?? this.homeGround,
      formatFocus: formatFocus ?? this.formatFocus,
      joinPolicy: joinPolicy ?? this.joinPolicy,
      saved: saved ?? this.saved,
    );
  }

  Map<String, dynamic> toJson() => {
    'baseline': baseline.toJson(),
    'name': name,
    'primaryColor': primaryColor.toARGB32(),
    'secondaryColor': secondaryColor.toARGB32(),
    'city': city,
    'homeGround': homeGround,
    'formatFocus': formatFocus.map((f) => f.name).toList(),
    'joinPolicy': joinPolicy.name,
    'saved': saved,
  };

  factory EditTeamState.fromJson(Map<String, dynamic> json) {
    return EditTeamState(
      baseline: EditTeamBaseline.fromJson(
        json['baseline'] as Map<String, dynamic>,
      ),
      name: json['name'] as String,
      primaryColor: Color(json['primaryColor'] as int),
      secondaryColor: Color(json['secondaryColor'] as int),
      city: json['city'] as String,
      homeGround: json['homeGround'] as String,
      formatFocus: {
        for (final f in (json['formatFocus'] as List? ?? const []))
          TeamFormat.values.byName(f as String),
      },
      joinPolicy: TeamJoinPolicy.values.byName(
        json['joinPolicy'] as String? ?? TeamJoinPolicy.open.name,
      ),
      saved: json['saved'] as bool? ?? false,
    );
  }
}

bool _setEquals(Set<TeamFormat> a, Set<TeamFormat> b) =>
    a.length == b.length && a.containsAll(b);

/// Unlike create_team_provider.dart's pure signup-wizard scratch state
/// (deliberately not persisted), this provider's [EditTeamState.baseline]
/// is the currently-saved team identity plus its append-only change log --
/// genuinely durable data, not in-progress form entry -- so the whole
/// state persists here via [PersistedNotifier].
class EditTeamNotifier extends PersistedNotifier<EditTeamState> {
  @override
  String get persistenceKey => 'edit_team_v1';

  @override
  Map<String, dynamic> toJson(EditTeamState value) => value.toJson();

  @override
  EditTeamState fromJson(Map<String, dynamic> json) =>
      EditTeamState.fromJson(json);

  @override
  EditTeamState seed() {
    final team = mockTeam();
    final baseline = EditTeamBaseline(
      name: team.name,
      primaryColor: team.primaryColor,
      secondaryColor: team.secondaryColor,
      city: team.city,
      homeGround: team.homeGround ?? '',
      formatFocus: team.formatFocus.toSet(),
      joinPolicy: team.joinPolicy,
    );
    return EditTeamState(
      baseline: baseline,
      name: baseline.name,
      primaryColor: baseline.primaryColor,
      secondaryColor: baseline.secondaryColor,
      city: baseline.city,
      homeGround: baseline.homeGround,
      formatFocus: baseline.formatFocus,
      joinPolicy: baseline.joinPolicy,
    );
  }

  void setName(String value) => state = state.copyWith(name: value);
  void setPrimaryColor(Color value) =>
      state = state.copyWith(primaryColor: value);
  void setSecondaryColor(Color value) =>
      state = state.copyWith(secondaryColor: value);
  void setCity(String value) => state = state.copyWith(city: value);
  void setHomeGround(String value) => state = state.copyWith(homeGround: value);
  void setJoinPolicy(TeamJoinPolicy value) =>
      state = state.copyWith(joinPolicy: value);

  void toggleFormat(TeamFormat format) {
    final formats = {...state.formatFocus};
    if (!formats.remove(format)) formats.add(format);
    state = state.copyWith(formatFocus: formats);
  }

  /// Returns false (without saving anything) if [EditTeamState.canSave]
  /// is false -- callers should already be disabling Save via that
  /// getter, this is the defensive backstop.
  bool save({DateTime Function() now = DateTime.now}) {
    if (!state.canSave) return false;

    var changeLog = state.baseline.changeLog;
    var formerName = state.baseline.formerName;
    var formerNameExpiresAt = state.baseline.formerNameExpiresAt;
    if (state.nameChanged) {
      changeLog = [
        ...changeLog,
        TeamIdentityChangeLogEntry(
          changedAt: now(),
          field: 'name',
          from: state.baseline.name,
          to: state.name.trim(),
        ),
      ];
      formerName = state.baseline.name;
      formerNameExpiresAt = now().add(
        const Duration(days: formerNameWindowDays),
      );
    }

    final newBaseline = EditTeamBaseline(
      name: state.name.trim(),
      primaryColor: state.primaryColor,
      secondaryColor: state.secondaryColor,
      city: state.city.trim(),
      homeGround: state.homeGround.trim(),
      formatFocus: state.formatFocus,
      joinPolicy: state.joinPolicy,
      changeLog: changeLog,
      formerName: formerName,
      formerNameExpiresAt: formerNameExpiresAt,
    );
    state = EditTeamState(
      baseline: newBaseline,
      name: newBaseline.name,
      primaryColor: newBaseline.primaryColor,
      secondaryColor: newBaseline.secondaryColor,
      city: newBaseline.city,
      homeGround: newBaseline.homeGround,
      formatFocus: newBaseline.formatFocus,
      joinPolicy: newBaseline.joinPolicy,
      saved: true,
    );
    return true;
  }

  void discard() {
    final baseline = state.baseline;
    state = EditTeamState(
      baseline: baseline,
      name: baseline.name,
      primaryColor: baseline.primaryColor,
      secondaryColor: baseline.secondaryColor,
      city: baseline.city,
      homeGround: baseline.homeGround,
      formatFocus: baseline.formatFocus,
      joinPolicy: baseline.joinPolicy,
    );
  }
}

final editTeamProvider = NotifierProvider<EditTeamNotifier, EditTeamState>(
  EditTeamNotifier.new,
);
