import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';

/// E2-02 · PRD §5.1: "name change limited to 2x/year (log kept)."
const int maxNameChangesPerYear = 2;

class NameChangeLogEntry {
  final DateTime changedAt;
  final String from;
  final String to;

  const NameChangeLogEntry({
    required this.changedAt,
    required this.from,
    required this.to,
  });

  Map<String, dynamic> toJson() => {
    'changedAt': changedAt.toIso8601String(),
    'from': from,
    'to': to,
  };

  factory NameChangeLogEntry.fromJson(Map<String, dynamic> json) {
    return NameChangeLogEntry(
      changedAt: DateTime.parse(json['changedAt'] as String),
      from: json['from'] as String,
      to: json['to'] as String,
    );
  }
}

/// The saved (server-side, in this mocked world) form of the profile --
/// what [EditProfileState.isDirty] compares the in-progress edits against.
class EditProfileBaseline {
  final String name;
  final String nickname;
  final String city;
  final bool showAgeBand;
  final Set<String> languages;
  final String bio;
  final String? equippedTitle;

  const EditProfileBaseline({
    required this.name,
    this.nickname = '',
    this.city = '',
    this.showAgeBand = true,
    this.languages = const {},
    this.bio = '',
    this.equippedTitle,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'nickname': nickname,
    'city': city,
    'showAgeBand': showAgeBand,
    'languages': languages.toList(),
    'bio': bio,
    'equippedTitle': equippedTitle,
  };

  factory EditProfileBaseline.fromJson(Map<String, dynamic> json) {
    return EditProfileBaseline(
      name: json['name'] as String,
      nickname: json['nickname'] as String? ?? '',
      city: json['city'] as String? ?? '',
      showAgeBand: json['showAgeBand'] as bool? ?? true,
      languages: {for (final l in json['languages'] as List) l as String},
      bio: json['bio'] as String? ?? '',
      equippedTitle: json['equippedTitle'] as String?,
    );
  }
}

class EditProfileState {
  final EditProfileBaseline baseline;
  final String name;
  final String nickname;
  final String city;
  final bool showAgeBand;
  final Set<String> languages;
  final String bio;
  final int nameChangesUsedThisYear;
  final List<NameChangeLogEntry> nameChangeLog;
  final bool saved;

  /// Equipping a title commits immediately (DS §11.18: a radio sheet with
  /// a live preview, not a field gated behind the outer Save button) --
  /// always mirrors [baseline.equippedTitle], so it never contributes to
  /// [isDirty].
  final String? equippedTitle;

  const EditProfileState({
    required this.baseline,
    required this.name,
    required this.nickname,
    required this.city,
    required this.showAgeBand,
    required this.languages,
    required this.bio,
    this.nameChangesUsedThisYear = 0,
    this.nameChangeLog = const [],
    this.saved = false,
    this.equippedTitle,
  });

  bool get nameChanged => name != baseline.name;

  int get nameChangesRemaining =>
      maxNameChangesPerYear - nameChangesUsedThisYear;

  /// A name edit that would exceed the yearly budget blocks the whole
  /// save (DS §7 screen 6: "sticky Save appears only on dirty state" --
  /// here it appears but stays disabled) rather than silently discarding
  /// just the name field.
  bool get nameChangeBlocked => nameChanged && nameChangesRemaining <= 0;

  bool get isDirty =>
      name != baseline.name ||
      nickname != baseline.nickname ||
      city != baseline.city ||
      showAgeBand != baseline.showAgeBand ||
      !_setEquals(languages, baseline.languages) ||
      bio != baseline.bio;

  bool get canSave => isDirty && !nameChangeBlocked && bio.length <= 150;

  EditProfileState copyWith({
    String? name,
    String? nickname,
    String? city,
    bool? showAgeBand,
    Set<String>? languages,
    String? bio,
    int? nameChangesUsedThisYear,
    List<NameChangeLogEntry>? nameChangeLog,
    bool? saved,
    String? equippedTitle,
    bool clearEquippedTitle = false,
  }) {
    return EditProfileState(
      baseline: baseline,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      city: city ?? this.city,
      showAgeBand: showAgeBand ?? this.showAgeBand,
      languages: languages ?? this.languages,
      bio: bio ?? this.bio,
      nameChangesUsedThisYear:
          nameChangesUsedThisYear ?? this.nameChangesUsedThisYear,
      nameChangeLog: nameChangeLog ?? this.nameChangeLog,
      saved: saved ?? this.saved,
      equippedTitle: clearEquippedTitle
          ? null
          : (equippedTitle ?? this.equippedTitle),
    );
  }

  Map<String, dynamic> toJson() => {
    'baseline': baseline.toJson(),
    'name': name,
    'nickname': nickname,
    'city': city,
    'showAgeBand': showAgeBand,
    'languages': languages.toList(),
    'bio': bio,
    'nameChangesUsedThisYear': nameChangesUsedThisYear,
    'nameChangeLog': [for (final e in nameChangeLog) e.toJson()],
    'saved': saved,
    'equippedTitle': equippedTitle,
  };

  factory EditProfileState.fromJson(Map<String, dynamic> json) {
    return EditProfileState(
      baseline: EditProfileBaseline.fromJson(
        json['baseline'] as Map<String, dynamic>,
      ),
      name: json['name'] as String,
      nickname: json['nickname'] as String? ?? '',
      city: json['city'] as String? ?? '',
      showAgeBand: json['showAgeBand'] as bool? ?? true,
      languages: {for (final l in json['languages'] as List) l as String},
      bio: json['bio'] as String? ?? '',
      nameChangesUsedThisYear: json['nameChangesUsedThisYear'] as int? ?? 0,
      nameChangeLog: [
        for (final e in json['nameChangeLog'] as List)
          NameChangeLogEntry.fromJson(e as Map<String, dynamic>),
      ],
      saved: json['saved'] as bool? ?? false,
      equippedTitle: json['equippedTitle'] as String?,
    );
  }
}

bool _setEquals(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);

class EditProfileNotifier extends PersistedNotifier<EditProfileState> {
  @override
  String get persistenceKey => 'edit_profile_v1';

  @override
  Map<String, dynamic> toJson(EditProfileState value) => value.toJson();

  @override
  EditProfileState fromJson(Map<String, dynamic> json) =>
      EditProfileState.fromJson(json);

  @override
  EditProfileState seed() {
    const baseline = EditProfileBaseline(name: 'Rohan Verma', city: 'Pune');
    return EditProfileState(
      baseline: baseline,
      name: baseline.name,
      nickname: baseline.nickname,
      city: baseline.city,
      showAgeBand: baseline.showAgeBand,
      languages: baseline.languages,
      bio: baseline.bio,
      equippedTitle: baseline.equippedTitle,
    );
  }

  void setName(String value) => state = state.copyWith(name: value);
  void setNickname(String value) => state = state.copyWith(nickname: value);
  void setCity(String value) => state = state.copyWith(city: value);
  void setShowAgeBand(bool value) => state = state.copyWith(showAgeBand: value);
  void setBio(String value) => state = state.copyWith(bio: value);

  void toggleLanguage(String language) {
    final languages = {...state.languages};
    if (!languages.remove(language)) languages.add(language);
    state = state.copyWith(languages: languages);
  }

  /// Commits immediately -- updates the baseline too, so this never shows
  /// up as a dirty/unsaved change (see [EditProfileState.equippedTitle]).
  void equipTitle(String? title) {
    final newBaseline = EditProfileBaseline(
      name: state.baseline.name,
      nickname: state.baseline.nickname,
      city: state.baseline.city,
      showAgeBand: state.baseline.showAgeBand,
      languages: state.baseline.languages,
      bio: state.baseline.bio,
      equippedTitle: title,
    );
    state = EditProfileState(
      baseline: newBaseline,
      name: state.name,
      nickname: state.nickname,
      city: state.city,
      showAgeBand: state.showAgeBand,
      languages: state.languages,
      bio: state.bio,
      nameChangesUsedThisYear: state.nameChangesUsedThisYear,
      nameChangeLog: state.nameChangeLog,
      equippedTitle: title,
    );
  }

  /// Returns false (without saving anything) if the name change would
  /// exceed the yearly budget -- callers should already be disabling Save
  /// via [EditProfileState.canSave], this is the defensive backstop.
  bool save({DateTime Function() now = DateTime.now}) {
    if (!state.canSave) return false;

    var nameChangesUsedThisYear = state.nameChangesUsedThisYear;
    var nameChangeLog = state.nameChangeLog;
    if (state.nameChanged) {
      nameChangesUsedThisYear += 1;
      nameChangeLog = [
        ...nameChangeLog,
        NameChangeLogEntry(
          changedAt: now(),
          from: state.baseline.name,
          to: state.name,
        ),
      ];
    }

    state = EditProfileState(
      baseline: EditProfileBaseline(
        name: state.name,
        nickname: state.nickname,
        city: state.city,
        showAgeBand: state.showAgeBand,
        languages: state.languages,
        bio: state.bio,
        equippedTitle: state.equippedTitle,
      ),
      name: state.name,
      nickname: state.nickname,
      city: state.city,
      showAgeBand: state.showAgeBand,
      languages: state.languages,
      bio: state.bio,
      nameChangesUsedThisYear: nameChangesUsedThisYear,
      nameChangeLog: nameChangeLog,
      saved: true,
      equippedTitle: state.equippedTitle,
    );
    return true;
  }

  /// Reverts in-progress edits back to the last saved baseline (the
  /// "Discard" side of the dirty-leave guard).
  void discard() {
    final baseline = state.baseline;
    state = EditProfileState(
      baseline: baseline,
      name: baseline.name,
      nickname: baseline.nickname,
      city: baseline.city,
      showAgeBand: baseline.showAgeBand,
      languages: baseline.languages,
      bio: baseline.bio,
      nameChangesUsedThisYear: state.nameChangesUsedThisYear,
      nameChangeLog: state.nameChangeLog,
      equippedTitle: baseline.equippedTitle,
    );
  }
}

final editProfileProvider =
    NotifierProvider<EditProfileNotifier, EditProfileState>(
      EditProfileNotifier.new,
    );
