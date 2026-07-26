import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  const EditProfileBaseline({
    required this.name,
    this.nickname = '',
    this.city = '',
    this.showAgeBand = true,
    this.languages = const {},
    this.bio = '',
  });
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
    );
  }
}

bool _setEquals(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);

class EditProfileNotifier extends Notifier<EditProfileState> {
  @override
  EditProfileState build() {
    const baseline = EditProfileBaseline(name: 'Rohan Verma', city: 'Pune');
    return EditProfileState(
      baseline: baseline,
      name: baseline.name,
      nickname: baseline.nickname,
      city: baseline.city,
      showAgeBand: baseline.showAgeBand,
      languages: baseline.languages,
      bio: baseline.bio,
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
    );
  }
}

final editProfileProvider =
    NotifierProvider<EditProfileNotifier, EditProfileState>(
      EditProfileNotifier.new,
    );
