import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../onboarding/profile_wizard_provider.dart';
import 'recruitment_models.dart';
import 'team_member_models.dart';

/// PRD §6.25 gives no explicit poster/manager role -- "team posts" is
/// read the same way Announcements/Documents' management actions were
/// (owner has "everything Captain has" per §2.9; VC/Manager included as
/// the standard team-management set used throughout Epic E3).
const Set<TeamMemberRole> recruitmentManagerRoles = {
  TeamMemberRole.owner,
  TeamMemberRole.captain,
  TeamMemberRole.viceCaptain,
  TeamMemberRole.manager,
};

class ListingResult {
  final String? error;
  final String? listingId;

  const ListingResult({this.error, this.listingId});

  bool get succeeded => error == null;
}

class ApplyResult {
  final String? error;

  const ApplyResult({this.error});

  bool get succeeded => error == null;
}

class RecruitmentBoardState {
  final List<RecruitmentListing> listings;
  final List<Applicant> applicants;

  const RecruitmentBoardState({
    this.listings = const [],
    this.applicants = const [],
  });

  RecruitmentBoardState copyWith({
    List<RecruitmentListing>? listings,
    List<Applicant>? applicants,
  }) {
    return RecruitmentBoardState(
      listings: listings ?? this.listings,
      applicants: applicants ?? this.applicants,
    );
  }
}

/// PRD §6.25 / DS §11.6: post composer -> listing cards; applicant
/// pipeline kanban-lite stages, drag between stages with
/// status-notification confirm (the confirm-before-move UI is the
/// screen's job -- this notifier only performs the move once the
/// caller has already confirmed it).
class RecruitmentBoardNotifier extends Notifier<RecruitmentBoardState> {
  @override
  RecruitmentBoardState build() => RecruitmentBoardState(
    listings: mockRecruitmentListings(),
    applicants: mockApplicants(),
  );

  ListingResult postListing({
    required String teamName,
    required PrimaryRole roleNeeded,
    required String dayTime,
    required String area,
    required TeamMemberRole actingRole,
    DateTime Function() now = DateTime.now,
  }) {
    if (!recruitmentManagerRoles.contains(actingRole)) {
      return const ListingResult(
        error: "You don't have permission to post a recruitment listing.",
      );
    }
    if (dayTime.trim().isEmpty || area.trim().isEmpty) {
      return const ListingResult(
        error: 'Add day/time and area before posting.',
      );
    }
    final id = 'listing-${now().millisecondsSinceEpoch}';
    state = state.copyWith(
      listings: [
        RecruitmentListing(
          id: id,
          teamName: teamName,
          roleNeeded: roleNeeded,
          dayTime: dayTime.trim(),
          area: area.trim(),
          postedAt: now(),
        ),
        ...state.listings,
      ],
    );
    return ListingResult(listingId: id);
  }

  ApplyResult apply({
    required String listingId,
    required String applicantName,
    DateTime Function() now = DateTime.now,
  }) {
    final listing = state.listings.firstWhere((l) => l.id == listingId);
    if (listing.isExpired(now: now)) {
      return const ApplyResult(error: 'This listing has expired.');
    }
    final alreadyApplied = state.applicants.any(
      (a) => a.listingId == listingId && a.applicantName == applicantName,
    );
    if (alreadyApplied) {
      return const ApplyResult(error: "You've already applied.");
    }
    state = state.copyWith(
      applicants: [
        ...state.applicants,
        Applicant(
          id: 'applicant-${now().millisecondsSinceEpoch}',
          listingId: listingId,
          applicantName: applicantName,
          stage: ApplicantStage.applied,
        ),
      ],
    );
    return const ApplyResult();
  }

  /// Moves an applicant to [newStage]. The screen is responsible for
  /// confirming the move with the acting user first (DS: "drag between
  /// stages with status-notification confirm") -- this method performs
  /// the move unconditionally once called.
  ApplyResult moveStage({
    required String applicantId,
    required ApplicantStage newStage,
    required TeamMemberRole actingRole,
  }) {
    if (!recruitmentManagerRoles.contains(actingRole)) {
      return const ApplyResult(
        error: "You don't have permission to manage the pipeline.",
      );
    }
    state = state.copyWith(
      applicants: [
        for (final a in state.applicants)
          if (a.id == applicantId) a.copyWith(stage: newStage) else a,
      ],
    );
    return const ApplyResult();
  }
}

final recruitmentBoardProvider =
    NotifierProvider<RecruitmentBoardNotifier, RecruitmentBoardState>(
      RecruitmentBoardNotifier.new,
    );
