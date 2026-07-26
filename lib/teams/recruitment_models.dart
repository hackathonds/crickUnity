import '../onboarding/profile_wizard_provider.dart';

/// PRD §6.25: "applicants tracked in a mini-pipeline (Applied -> Trial
/// invited -> Offered -> Joined)."
enum ApplicantStage { applied, trialInvited, offered, joined }

const Map<ApplicantStage, String> applicantStageLabels = {
  ApplicantStage.applied: 'Applied',
  ApplicantStage.trialInvited: 'Trial invited',
  ApplicantStage.offered: 'Offered',
  ApplicantStage.joined: 'Joined',
};

/// Column order for the kanban-lite pipeline board (DS §11.6). Unlike
/// Jersey Board's order tracker (E3-09), the backlog/DS give no
/// sequential-only constraint for this pipeline -- a captain may drag a
/// card to any stage (including backward, e.g. a "Joined" candidate who
/// backs out returning to "Applied"), so this list is display order
/// only, not an enforced progression.
const List<ApplicantStage> applicantStageOrder = [
  ApplicantStage.applied,
  ApplicantStage.trialInvited,
  ApplicantStage.offered,
  ApplicantStage.joined,
];

/// PRD's own illustrative listing ("Need: Left-arm spinner, Sun
/// mornings, North Delhi") is finer-grained than any role taxonomy that
/// exists in this codebase, but DS §11.6 explicitly calls the field a
/// "role-needed chip" -- reusing the existing [PrimaryRole] enum (the
/// only role taxonomy in the codebase, from the profile wizard) for the
/// chip rather than inventing a new bowling-style/arm sub-taxonomy that
/// nothing else uses. day/time and area stay free text so a poster can
/// still capture PRD's finer nuance there.
class RecruitmentListing {
  final String id;
  final String teamName;
  final PrimaryRole roleNeeded;
  final String dayTime;
  final String area;
  final DateTime postedAt;

  const RecruitmentListing({
    required this.id,
    required this.teamName,
    required this.roleNeeded,
    required this.dayTime,
    required this.area,
    required this.postedAt,
  });

  /// PRD screen table (#29) requires an "expired-listing state" but no
  /// section anywhere gives a concrete listing lifetime -- 30 days is a
  /// judgment-call default (longer than Join-request's 14 days and
  /// Invite-link's 7 days, since a recruitment need is open-ended
  /// rather than a single decision awaiting one person).
  bool isExpired({DateTime Function() now = DateTime.now}) =>
      now().difference(postedAt).inDays >= listingExpiryDays;
}

const int listingExpiryDays = 30;

class Applicant {
  final String id;
  final String listingId;
  final String applicantName;
  final ApplicantStage stage;

  const Applicant({
    required this.id,
    required this.listingId,
    required this.applicantName,
    required this.stage,
  });

  Applicant copyWith({ApplicantStage? stage}) {
    return Applicant(
      id: id,
      listingId: listingId,
      applicantName: applicantName,
      stage: stage ?? this.stage,
    );
  }
}

/// Mock seed data for the debug demo and tests -- no backend
/// recruitment-board service exists yet.
List<RecruitmentListing> mockRecruitmentListings({
  DateTime Function() now = DateTime.now,
}) => [
  RecruitmentListing(
    id: 'listing-1',
    teamName: 'Riverside Strikers',
    roleNeeded: PrimaryRole.bowler,
    dayTime: 'Sunday mornings',
    area: 'North Delhi',
    postedAt: now().subtract(const Duration(days: 5)),
  ),
];

List<Applicant> mockApplicants() => const [
  Applicant(
    id: 'applicant-1',
    listingId: 'listing-1',
    applicantName: 'Karan Bhatt',
    stage: ApplicantStage.applied,
  ),
];
