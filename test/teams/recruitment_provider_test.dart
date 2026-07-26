import 'package:cricunity/onboarding/profile_wizard_provider.dart';
import 'package:cricunity/teams/recruitment_models.dart';
import 'package:cricunity/teams/recruitment_provider.dart';
import 'package:cricunity/teams/team_member_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AC: a privileged role can post a recruitment listing', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(recruitmentBoardProvider.notifier);

    final result = notifier.postListing(
      teamName: 'Riverside Strikers',
      roleNeeded: PrimaryRole.wicketKeeper,
      dayTime: 'Saturday evenings',
      area: 'South Mumbai',
      actingRole: TeamMemberRole.captain,
    );

    expect(result.succeeded, isTrue);
    expect(
      container
          .read(recruitmentBoardProvider)
          .listings
          .any((l) => l.id == result.listingId),
      isTrue,
    );
  });

  test('a plain player cannot post a recruitment listing', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(recruitmentBoardProvider.notifier);
    final before = container.read(recruitmentBoardProvider).listings.length;

    final result = notifier.postListing(
      teamName: 'Riverside Strikers',
      roleNeeded: PrimaryRole.batter,
      dayTime: 'Sunday',
      area: 'Delhi',
      actingRole: TeamMemberRole.player,
    );

    expect(result.succeeded, isFalse);
    expect(container.read(recruitmentBoardProvider).listings.length, before);
  });

  test('AC: a free agent can apply to an open listing', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(recruitmentBoardProvider.notifier);

    final result = notifier.apply(
      listingId: 'listing-1',
      applicantName: 'Neha Rao',
    );

    expect(result.succeeded, isTrue);
    expect(
      container
          .read(recruitmentBoardProvider)
          .applicants
          .any((a) => a.applicantName == 'Neha Rao'),
      isTrue,
    );
  });

  test('applying twice to the same listing is rejected', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(recruitmentBoardProvider.notifier);

    // Mock data already has Karan Bhatt applied to listing-1.
    final result = notifier.apply(
      listingId: 'listing-1',
      applicantName: 'Karan Bhatt',
    );

    expect(result.succeeded, isFalse);
  });

  test('AC: applying to an expired listing is rejected', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(recruitmentBoardProvider.notifier);
    final farFuture = DateTime.now().add(const Duration(days: 40));

    final result = notifier.apply(
      listingId: 'listing-1',
      applicantName: 'Neha Rao',
      now: () => farFuture,
    );

    expect(result.succeeded, isFalse);
  });

  test('AC: a privileged role can move an applicant between stages', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(recruitmentBoardProvider.notifier);

    final result = notifier.moveStage(
      applicantId: 'applicant-1',
      newStage: ApplicantStage.trialInvited,
      actingRole: TeamMemberRole.captain,
    );

    expect(result.succeeded, isTrue);
    final applicant = container
        .read(recruitmentBoardProvider)
        .applicants
        .firstWhere((a) => a.id == 'applicant-1');
    expect(applicant.stage, ApplicantStage.trialInvited);
  });

  test('a plain player cannot move an applicant between stages', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(recruitmentBoardProvider.notifier);

    final result = notifier.moveStage(
      applicantId: 'applicant-1',
      newStage: ApplicantStage.trialInvited,
      actingRole: TeamMemberRole.player,
    );

    expect(result.succeeded, isFalse);
    final applicant = container
        .read(recruitmentBoardProvider)
        .applicants
        .firstWhere((a) => a.id == 'applicant-1');
    expect(applicant.stage, ApplicantStage.applied);
  });
}
