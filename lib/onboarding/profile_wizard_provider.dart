import 'package:flutter_riverpod/flutter_riverpod.dart';

/// E1-03 · DS §11.3 Profile wizard: "photo (camera/library/skip) -> city
/// (auto-suggest) -> playing info chips; completeness meter fills live;
/// every skip allowed."
///
/// Playing info uses a representative subset of PRD's player-profile field
/// list (primary role, batting style) -- not the full profile editor
/// (bowling style, preferred formats, jersey/team fields), which belongs
/// to a later profile-editing story, not this lightweight onboarding touch.
enum PrimaryRole { batter, bowler, allRounder, wicketKeeper }

enum BattingStyle { rhb, lhb }

class ProfileWizardState {
  final bool photoSet;
  final String? city;
  final PrimaryRole? primaryRole;
  final BattingStyle? battingStyle;

  const ProfileWizardState({
    this.photoSet = false,
    this.city,
    this.primaryRole,
    this.battingStyle,
  });

  static const int fieldCount = 4;

  int get filledFieldCount =>
      (photoSet ? 1 : 0) +
      (city != null ? 1 : 0) +
      (primaryRole != null ? 1 : 0) +
      (battingStyle != null ? 1 : 0);

  double get completeness => filledFieldCount / fieldCount;

  ProfileWizardState copyWith({
    bool? photoSet,
    String? city,
    bool clearCity = false,
    PrimaryRole? primaryRole,
    bool clearPrimaryRole = false,
    BattingStyle? battingStyle,
    bool clearBattingStyle = false,
  }) {
    return ProfileWizardState(
      photoSet: photoSet ?? this.photoSet,
      city: clearCity ? null : (city ?? this.city),
      primaryRole: clearPrimaryRole ? null : (primaryRole ?? this.primaryRole),
      battingStyle: clearBattingStyle
          ? null
          : (battingStyle ?? this.battingStyle),
    );
  }
}

class ProfileWizardNotifier extends Notifier<ProfileWizardState> {
  @override
  ProfileWizardState build() => const ProfileWizardState();

  void setPhotoSet(bool value) => state = state.copyWith(photoSet: value);

  void setCity(String? city) => state = city == null
      ? state.copyWith(clearCity: true)
      : state.copyWith(city: city);

  void setPrimaryRole(PrimaryRole? role) => state = role == null
      ? state.copyWith(clearPrimaryRole: true)
      : state.copyWith(primaryRole: role);

  void setBattingStyle(BattingStyle? style) => state = style == null
      ? state.copyWith(clearBattingStyle: true)
      : state.copyWith(battingStyle: style);

  void reset() => state = const ProfileWizardState();
}

final profileWizardProvider =
    NotifierProvider<ProfileWizardNotifier, ProfileWizardState>(
      ProfileWizardNotifier.new,
    );
