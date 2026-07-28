import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../expenses/expense_models.dart';
import '../expenses/expenses_provider.dart';
import '../expenses/reminders_provider.dart';
import '../expenses/settlement_models.dart';
import '../expenses/settlements_provider.dart';
import '../grounds/booking_models.dart';
import '../grounds/bookings_provider.dart';
import '../grounds/ground_models.dart';
import '../grounds/grounds_provider.dart';
import '../grounds/reviews_provider.dart';
import '../matches/match_models.dart';
import '../matches/matches_provider.dart';
import '../matches/scoring_provider.dart';
import '../messaging/chat_provider.dart';
import '../moderation/moderation_provider.dart';
import '../moderation/report_models.dart';
import '../recognition/personal_bests_provider.dart';
import '../rewards/rewards_models.dart';
import '../rewards/rewards_provider.dart';
import '../rewards/streaks_provider.dart';
import '../social/composer_screen.dart' show composerViewerName;
import '../teams/announcement_models.dart';
import '../teams/announcements_provider.dart';
import '../teams/availability_matrix_models.dart';
import '../teams/join_request_models.dart';
import '../teams/join_requests_provider.dart';
import '../teams/practice_session_provider.dart';
import '../tournaments/fixture_models.dart';
import '../tournaments/fixtures_provider.dart';
import '../tournaments/ledger_provider.dart';
import '../tournaments/registration_models.dart';
import '../tournaments/registrations_provider.dart';
import '../tournaments/tournaments_provider.dart';
import 'notification_models.dart';

/// PRD §15's canonical catalog, wired to real cross-module state
/// wherever this codebase has a genuine data source for it (E12-05).
/// The single logged-in identity is [composerViewerName], same
/// convention used by every other cross-module feature this session.
/// The viewer's own team is always 'Strikers CC' -- the one team name
/// this session's mocks consistently cast the viewer as a member of
/// (E9-06 bookings, E12-01/03/04 seeds).
const String _myTeamName = 'Strikers CC';

List<NotificationCard> generateCatalogCards(Ref ref, DateTime now) {
  final cards = <NotificationCard>[];
  cards.addAll(_matchCards(ref, now));
  cards.addAll(_scorecardCard(ref, now));
  cards.addAll(_expenseCards(ref, now));
  cards.addAll(_settlementCards(ref, now));
  cards.addAll(_teamCards(ref, now));
  cards.addAll(_tournamentCards(ref, now));
  cards.addAll(_bookingCards(ref, now));
  cards.addAll(_followedGroundCards(ref, now));
  cards.addAll(_rewardsCards(ref, now));
  cards.addAll(_moderationCards(ref, now));
  cards.addAll(_paymentReminderCards(ref, now));
  cards.addAll(_practiceReminderCards(ref, now));
  cards.addAll(_levelUpAndPbCards(ref, now));
  cards.addAll(_messageCards(ref, now));
  cards.addAll(_reviewReplyCards(ref, now));
  cards.addAll(_unwiredCatalogRows(now));
  return cards;
}

/// PRD §15 rows: "Availability poll," "Availability deadline nearing,"
/// "Match starts soon," "Match cancelled/rescheduled." Real read of
/// [matchesProvider] -- squad membership, poll/deadline state, and
/// status all come from the actual [MatchRecord], not a mock.
List<NotificationCard> _matchCards(Ref ref, DateTime now) {
  final matches = ref.read(matchesProvider).matches;
  final cards = <NotificationCard>[];

  for (final m in matches) {
    if (!m.squadNames.contains(composerViewerName)) continue;
    final entity = m.composerTeamName;

    if (m.status == MatchStatus.cancelled) {
      cards.add(
        NotificationCard(
          id: 'match-cancelled-${m.id}',
          tab: NotificationTab.forYou,
          entityName: entity,
          title: 'Match cancelled -- ${m.cancelledReason ?? 'see details'}',
          priority: NotificationPriority.p0,
          channel: NotificationChannel.matches,
          actions: const [NotificationActionType.viewReason],
          createdAt: now,
        ),
      );
      continue;
    }

    if (m.status != MatchStatus.accepted) continue;

    if (m.rescheduleReason != null) {
      cards.add(
        NotificationCard(
          id: 'match-rescheduled-${m.id}',
          tab: NotificationTab.forYou,
          entityName: entity,
          title: 'Match rescheduled -- ${m.rescheduleReason}',
          priority: NotificationPriority.p0,
          channel: NotificationChannel.matches,
          actions: const [
            NotificationActionType.viewReason,
            NotificationActionType.reRsvp,
          ],
          createdAt: now,
        ),
      );
    }

    final responded = m.availabilityResponses.containsKey(composerViewerName);
    if (m.availabilityPollSent && !responded) {
      cards.add(
        NotificationCard(
          id: 'match-availability-poll-${m.id}',
          tab: NotificationTab.forYou,
          entityName: entity,
          title:
              'Availability poll: are you in for '
              '${m.draft.opponentTeamName.isEmpty ? 'the match' : 'vs ${m.draft.opponentTeamName}'}?',
          priority: NotificationPriority.p1,
          channel: NotificationChannel.matches,
          actions: const [
            NotificationActionType.rsvpYes,
            NotificationActionType.rsvpNo,
          ],
          createdAt: now,
          // PRD §15: availability follow-ups run on the captain's own
          // deadline, not the generic 24h rule.
          followUpExempt: true,
        ),
      );

      final deadline = m.availabilityDeadline;
      if (deadline != null &&
          deadline.isAfter(now) &&
          deadline.difference(now) <= const Duration(hours: 12)) {
        cards.add(
          NotificationCard(
            id: 'match-availability-deadline-${m.id}',
            tab: NotificationTab.forYou,
            entityName: entity,
            title: 'Availability deadline in less than 12h -- respond now',
            priority: NotificationPriority.p1,
            channel: NotificationChannel.matches,
            actions: const [
              NotificationActionType.rsvpYes,
              NotificationActionType.rsvpNo,
            ],
            createdAt: now,
            followUpExempt: true,
          ),
        );
      }
    }

    final untilStart = m.draft.dateTime.difference(now);
    if (untilStart.inMinutes > 0 && untilStart <= const Duration(hours: 24)) {
      final isSoon = untilStart <= const Duration(hours: 2);
      cards.add(
        NotificationCard(
          id: 'match-starts-soon-${m.id}-${isSoon ? '2h' : '24h'}',
          tab: NotificationTab.forYou,
          entityName: entity,
          title: isSoon
              ? 'Match starts in 2h -- ${m.draft.groundName}'
              : 'Match tomorrow -- ${m.draft.groundName}',
          priority: isSoon ? NotificationPriority.p0 : NotificationPriority.p1,
          channel: NotificationChannel.matches,
          actions: const [
            NotificationActionType.directions,
            NotificationActionType.checkIn,
          ],
          createdAt: now,
          isSameDayMatchLogistics: isSoon,
        ),
      );
    }
  }
  return cards;
}

/// PRD §15 row: "Scorecard confirmation needed." Real read of the
/// single live [inningsProvider] console (this codebase models one
/// scorer console, not a per-match innings map -- see
/// scoring_provider.dart).
List<NotificationCard> _scorecardCard(Ref ref, DateTime now) {
  final innings = ref.read(inningsProvider);
  if (innings.isFullyConfirmed || innings.deliveries.isEmpty) return const [];
  return [
    NotificationCard(
      id: 'scorecard-confirmation-${innings.scorecardPostedAt.millisecondsSinceEpoch}',
      tab: NotificationTab.forYou,
      entityName: innings.battingTeamName,
      title:
          'Scorecard confirmation needed -- '
          '${innings.battingTeamName} vs ${innings.bowlingTeamName}',
      priority: NotificationPriority.p1,
      channel: NotificationChannel.matches,
      actions: const [
        NotificationActionType.confirm,
        NotificationActionType.dispute,
      ],
      createdAt: innings.scorecardPostedAt,
    ),
  ];
}

/// PRD §15 rows: "Your share finalized (₹X)," "Expense disputed." Real
/// read of [expensesProvider]; [Expense.netFor] is the actual owed
/// amount for the viewer.
List<NotificationCard> _expenseCards(Ref ref, DateTime now) {
  final expenses = ref.read(expensesProvider).expenses;
  final cards = <NotificationCard>[];
  for (final e in expenses) {
    if (e.isDeleted) continue;
    final net = e.netFor(composerViewerName);
    if (e.approvalState != ExpenseApprovalState.pendingApproval &&
        net < 0 &&
        e.splitAmong.any((s) => s.name == composerViewerName)) {
      cards.add(
        NotificationCard(
          id: 'expense-share-${e.id}',
          tab: NotificationTab.forYou,
          entityName: _myTeamName,
          title: 'Your share finalized: ₹${-net} for ${e.title}',
          priority: NotificationPriority.p1,
          channel: NotificationChannel.money,
          actions: const [
            NotificationActionType.pay,
            NotificationActionType.view,
          ],
          createdAt: e.date,
          // PRD §11.10's own auto-reminder cadence (remindersProvider)
          // governs this card's follow-up, not the generic 24h rule.
          followUpExempt: true,
        ),
      );
    }
    if (e.hasActiveDispute &&
        e.disputes.any(
          (d) => !d.resolved && d.disputerName != composerViewerName,
        )) {
      cards.add(
        NotificationCard(
          id: 'expense-disputed-${e.id}',
          tab: NotificationTab.forYou,
          entityName: _myTeamName,
          title: '${e.title} disputed -- review needed',
          priority: NotificationPriority.p1,
          channel: NotificationChannel.money,
          actions: const [NotificationActionType.view],
          createdAt: e.date,
        ),
      );
    }
  }
  return cards;
}

/// PRD §15 row: "Payment received — confirm." Real read of
/// [settlementsProvider].
List<NotificationCard> _settlementCards(Ref ref, DateTime now) {
  final settlements = ref.read(settlementsProvider).settlements;
  return [
    for (final s in settlements)
      if (s.toName == composerViewerName &&
          s.status == SettlementStatus.pendingConfirmation)
        NotificationCard(
          id: 'settlement-confirm-${s.id}',
          tab: NotificationTab.forYou,
          entityName: s.fromName,
          title: 'Payment received -- confirm ₹${s.amount} from ${s.fromName}',
          priority: NotificationPriority.p1,
          channel: NotificationChannel.money,
          actions: const [
            NotificationActionType.confirm,
            NotificationActionType.notReceived,
          ],
          createdAt: s.createdAt,
          followUpExempt: true,
        ),
  ];
}

/// PRD §15 rows: "Team invite / join request," "Announcement." Real
/// reads of [joinRequestsProvider] and [announcementsProvider].
List<NotificationCard> _teamCards(Ref ref, DateTime now) {
  final cards = <NotificationCard>[];

  final pendingRequests = ref.read(joinRequestsProvider).pending;
  for (final JoinRequest r in pendingRequests) {
    if (r.isExpired(now: () => now)) continue;
    cards.add(
      NotificationCard(
        id: 'join-request-${r.id}',
        tab: NotificationTab.forYou,
        entityName: _myTeamName,
        title: 'Join request from ${r.requesterName}',
        priority: NotificationPriority.p1,
        channel: NotificationChannel.team,
        actions: const [
          NotificationActionType.accept,
          NotificationActionType.decline,
        ],
        createdAt: r.requestedAt,
      ),
    );
  }

  final announcements = ref.read(announcementsProvider).announcements;
  for (final Announcement a in announcements) {
    if (a.authorName == composerViewerName) continue;
    if (a.seenBy.contains(composerViewerName)) continue;
    cards.add(
      NotificationCard(
        id: 'announcement-${a.id}',
        tab: NotificationTab.forYou,
        entityName: _myTeamName,
        title: a.body,
        priority: NotificationPriority.p1,
        channel: NotificationChannel.team,
        actions: const [NotificationActionType.view],
        createdAt: a.postedAt,
      ),
    );
  }
  return cards;
}

/// PRD §15 rows: "Tournament fixture published/changed," "Registration
/// approved / waitlist promoted," "Prize payout sent." Real reads of
/// [fixturesProvider], [registrationsProvider], [ledgerProvider].
List<NotificationCard> _tournamentCards(Ref ref, DateTime now) {
  final cards = <NotificationCard>[];
  final tournaments = ref.read(tournamentsProvider).tournaments;
  final myRegistrations = ref
      .read(registrationsProvider)
      .registrations
      .where((r) => r.teamName == _myTeamName)
      .toList();

  for (final r in myRegistrations) {
    final t = tournaments.where((t) => t.id == r.tournamentId).firstOrNull;
    if (t == null) continue;
    // PRD §15 catalog row combines "Registration approved / waitlist
    // promoted" into one trigger. [RegistrationsNotifier._promoteFromWaitlist]
    // just flips a promoted registration's status back to pending with
    // no history flag, so it's indistinguishable from an ordinary
    // never-waitlisted pending registration -- only the unambiguous
    // "approved" transition is wired here; "waitlist promoted" would
    // need a real signal this provider doesn't expose yet (flagged,
    // not guessed).
    if (r.status == RegistrationStatus.approved) {
      cards.add(
        NotificationCard(
          id: 'registration-approved-${r.id}',
          tab: NotificationTab.following,
          entityName: t.name,
          title: 'Registration approved for $_myTeamName',
          priority: NotificationPriority.p1,
          channel: NotificationChannel.tournaments,
          actions: const [NotificationActionType.view],
          createdAt: r.createdAt,
        ),
      );
    }

    final fixtures = ref
        .read(fixturesProvider)
        .fixtures
        .where(
          (f) =>
              f.tournamentId == r.tournamentId &&
              (f.homeRegistrationId == r.id || f.awayRegistrationId == r.id),
        );
    for (final Fixture f in fixtures) {
      if (f.changeHistory.isNotEmpty) {
        final change = f.changeHistory.last;
        cards.add(
          NotificationCard(
            id: 'fixture-changed-${f.id}-${change.changedAt.millisecondsSinceEpoch}',
            tab: NotificationTab.following,
            entityName: t.name,
            title: 'Fixture changed -- ${change.reason}',
            priority: NotificationPriority.p1,
            channel: NotificationChannel.tournaments,
            actions: const [NotificationActionType.view],
            createdAt: change.changedAt,
          ),
        );
      } else if (f.isScheduled) {
        cards.add(
          NotificationCard(
            id: 'fixture-published-${f.id}',
            tab: NotificationTab.following,
            entityName: t.name,
            title:
                'Fixture published -- vs '
                '${f.homeTeamName == _myTeamName ? f.awayTeamName : f.homeTeamName}',
            priority: NotificationPriority.p1,
            channel: NotificationChannel.tournaments,
            actions: const [NotificationActionType.view],
            createdAt: t.startDate ?? now,
          ),
        );
      }
    }
  }

  final payouts = ref
      .read(ledgerProvider)
      .payoutsByTournament
      .values
      .expand((list) => list);
  for (final payout in payouts) {
    if (payout.winnerTeamName != _myTeamName) continue;
    final t = tournaments.where((t) => t.id == payout.tournamentId).firstOrNull;
    cards.add(
      NotificationCard(
        id: 'prize-payout-${payout.id}',
        tab: NotificationTab.following,
        entityName: t?.name ?? payout.tournamentId,
        title: 'Prize payout sent -- ₹${payout.amount}',
        priority: NotificationPriority.p1,
        channel: NotificationChannel.money,
        actions: payout.isConfirmed
            ? const []
            : const [NotificationActionType.confirmReceipt],
        createdAt: payout.awardedAt,
        read: payout.isConfirmed,
      ),
    );
  }
  return cards;
}

/// PRD §15 row: "Booking confirmed / slot reminder." Real read of
/// [bookingsProvider] -- [Booking.qrCode] reused directly, same as
/// E12-03's QR registry.
List<NotificationCard> _bookingCards(Ref ref, DateTime now) {
  final bookings = ref.read(bookingsProvider).bookings;
  final cards = <NotificationCard>[];
  for (final Booking b in bookings) {
    if (b.status == BookingStatus.confirmed) {
      cards.add(
        NotificationCard(
          id: 'booking-confirmed-${b.id}',
          tab: NotificationTab.following,
          entityName: b.groundName,
          title: 'Booking confirmed -- ${b.groundName}',
          priority: NotificationPriority.p1,
          channel: NotificationChannel.bookings,
          actions: const [NotificationActionType.view],
          createdAt: b.createdAt,
        ),
      );
      final untilSlot = b.slotStart.difference(now);
      if (untilSlot.inMinutes > 0 && untilSlot <= const Duration(days: 1)) {
        cards.add(
          NotificationCard(
            id: 'booking-reminder-${b.id}',
            tab: NotificationTab.following,
            entityName: b.groundName,
            title: 'Slot reminder -- ${b.groundName} tomorrow',
            priority: NotificationPriority.p1,
            channel: NotificationChannel.bookings,
            actions: const [
              NotificationActionType.directions,
              NotificationActionType.checkIn,
            ],
            createdAt: now,
          ),
        );
      }
    }
  }
  return cards;
}

/// Backlog addendum: "E9-02: followed grounds emit new-slot and
/// price-drop notifications (PRD §10.4) -- add rows to E12-05 catalog
/// config." PRD §10.4: "Follow a ground -> new-slot alerts, price-drop
/// alerts, review-milestone digest." E9-02 already built the real
/// follow relationship ([GroundsState.followedGroundIds] -- its own
/// doc comment there explicitly deferred the alert-firing to this
/// story). The relationship is real; a genuine trigger isn't, since no
/// slot-availability calendar or historical price series exists on
/// [Ground] to detect an actual new slot or a real price drop from
/// (flagged, same convention as every other missing-signal gap this
/// session) -- one representative flagged-mock card per followed
/// ground stands in for whichever of the two PRD names would fire.
List<NotificationCard> _followedGroundCards(Ref ref, DateTime now) {
  final groundsState = ref.read(groundsProvider);
  final followed = groundsState.grounds.where(
    (g) => groundsState.followedGroundIds.contains(g.id),
  );
  return [
    for (final Ground g in followed)
      NotificationCard(
        id: 'ground-followed-alert-${g.id}',
        tab: NotificationTab.following,
        entityName: g.name,
        title:
            'New slot opened up at ${g.name} this week (mock alert -- '
            'no real slot-calendar/price-history signal exists yet)',
        priority: NotificationPriority.p2,
        channel: NotificationChannel.bookings,
        actions: const [NotificationActionType.view],
        createdAt: now.subtract(const Duration(hours: 12)),
      ),
  ];
}

/// PRD §15 rows: "Coins credited / badge earned," "Streak at risk,"
/// "Coins expiring." Real reads of [rewardsProvider] and
/// [streaksProvider].
List<NotificationCard> _rewardsCards(Ref ref, DateTime now) {
  final cards = <NotificationCard>[];
  final rewards = ref.read(rewardsProvider);
  if (rewards.log.isNotEmpty) {
    cards.add(
      NotificationCard(
        id: 'coins-credited-${rewards.log.length}',
        tab: NotificationTab.forYou,
        entityName: 'CricUnity Rewards',
        title: rewards.log.last,
        priority: NotificationPriority.p2,
        channel: NotificationChannel.rewards,
        actions: const [
          NotificationActionType.view,
          NotificationActionType.share,
        ],
        createdAt: now,
      ),
    );
  }
  final expiringSoon = coinsExpiringWithin(
    rewards.coinBatches,
    30,
    now: () => now,
  );
  if (expiringSoon > 0) {
    cards.add(
      NotificationCard(
        id: 'coins-expiring',
        tab: NotificationTab.forYou,
        entityName: 'CricUnity Rewards',
        title: '$expiringSoon coins expiring within 30 days',
        priority: NotificationPriority.p2,
        channel: NotificationChannel.rewards,
        actions: const [NotificationActionType.redeem],
        createdAt: now,
      ),
    );
  }

  final streak = ref.read(streaksProvider);
  final loggedInToday =
      streak.lastLoginDate != null &&
      DateTime(
            streak.lastLoginDate!.year,
            streak.lastLoginDate!.month,
            streak.lastLoginDate!.day,
          ) ==
          DateTime(now.year, now.month, now.day);
  if (streak.currentLoginStreakDays > 0 &&
      !loggedInToday &&
      !streak.injuryModeActive &&
      now.hour >= 20) {
    cards.add(
      NotificationCard(
        id: 'streak-at-risk-${now.year}-${now.month}-${now.day}',
        tab: NotificationTab.forYou,
        entityName: 'CricUnity Rewards',
        title: 'Streak at risk -- do a mission before 20:00 tomorrow',
        priority: NotificationPriority.p2,
        channel: NotificationChannel.rewards,
        actions: const [NotificationActionType.doAMission],
        createdAt: now,
      ),
    );
  }
  return cards;
}

/// PRD §15 row: "Conduct report filed on you." Real read of
/// [moderationProvider] -- reports where the viewer is the reported
/// party.
List<NotificationCard> _moderationCards(Ref ref, DateTime now) {
  final reports = ref.read(moderationProvider).reports;
  return [
    for (final Report r in reports)
      if (r.targetUserName == composerViewerName &&
          r.status == ReportStatus.pending)
        NotificationCard(
          id: 'conduct-report-${r.id}',
          tab: NotificationTab.forYou,
          entityName: 'CricUnity Safety',
          title:
              'A conduct report was filed on you -- ${reportReasonLabels[r.reason]}',
          priority: NotificationPriority.p1,
          channel: NotificationChannel.safetyAccount,
          actions: const [NotificationActionType.respond],
          createdAt: r.createdAt,
        ),
  ];
}

/// PRD §15 row: "Payment reminder." Distinct from "Your share
/// finalized" (which fires once, at finalization) -- this is the
/// ongoing §11.10 cadence (T+3d gentle, T+7d firm, weekly after). Real
/// read of [expensesProvider]/[remindersProvider]; only fires once the
/// gentle threshold is reached.
List<NotificationCard> _paymentReminderCards(Ref ref, DateTime now) {
  final expenses = ref.read(expensesProvider).expenses;
  final cards = <NotificationCard>[];
  for (final e in expenses) {
    if (e.isDeleted) continue;
    if (e.approvalState == ExpenseApprovalState.pendingApproval) continue;
    final net = e.netFor(composerViewerName);
    if (net >= 0 || !e.splitAmong.any((s) => s.name == composerViewerName)) {
      continue;
    }
    final ageDays = now.difference(e.date).inDays;
    if (ageDays < 3) continue;
    cards.add(
      NotificationCard(
        id: 'payment-reminder-${e.id}-${ageDays ~/ 7}',
        tab: NotificationTab.forYou,
        entityName: _myTeamName,
        title:
            '${reminderCopy(amount: -net, contextCaption: e.title)} -- '
            '${reminderCadenceLabel(ageDays)}',
        priority: NotificationPriority.p1,
        channel: NotificationChannel.money,
        actions: const [
          NotificationActionType.pay,
          NotificationActionType.snooze,
        ],
        createdAt: e.date,
        followUpExempt: true,
      ),
    );
  }
  return cards;
}

/// PRD §15 row: "Practice reminder." Real read of
/// [practiceSessionProvider] -- only fires for a roster member who
/// RSVP'd yes, within the −3h window before the session.
List<NotificationCard> _practiceReminderCards(Ref ref, DateTime now) {
  final session = ref.read(practiceSessionProvider).session;
  if (!session.roster.contains(composerViewerName)) return const [];
  if (session.rsvps[composerViewerName] != AvailabilityResponse.yes) {
    return const [];
  }
  final untilStart = session.scheduledAt.difference(now);
  if (untilStart.inMinutes <= 0 || untilStart > const Duration(hours: 3)) {
    return const [];
  }
  return [
    NotificationCard(
      id: 'practice-reminder-${session.scheduledAt.millisecondsSinceEpoch}',
      tab: NotificationTab.forYou,
      entityName: _myTeamName,
      title: 'Practice at ${session.venueName} in less than 3h',
      priority: NotificationPriority.p2,
      channel: NotificationChannel.team,
      actions: const [NotificationActionType.checkIn],
      createdAt: now,
    ),
  ];
}

/// PRD §15 row: "Level up / rank PB." Real reads of
/// [rewardsProvider]'s ceremony queue (E6-01's genuine level-up
/// signal, not a re-derived one) and [personalBestsProvider]'s real PB
/// announcements (E8-04).
List<NotificationCard> _levelUpAndPbCards(Ref ref, DateTime now) {
  final cards = <NotificationCard>[];
  final ceremonies = ref.read(rewardsProvider).ceremonyQueue;
  for (final c in ceremonies) {
    if (c.type != CeremonyType.levelUp) continue;
    cards.add(
      NotificationCard(
        id: 'level-up-${c.level}',
        tab: NotificationTab.forYou,
        entityName: 'CricUnity Rewards',
        title: 'Level up! You reached level ${c.level}',
        priority: NotificationPriority.p2,
        channel: NotificationChannel.rewards,
        actions: const [NotificationActionType.share],
        createdAt: now,
      ),
    );
  }
  final pbAnnouncements = ref.read(personalBestsProvider).announcements;
  if (pbAnnouncements.isNotEmpty) {
    cards.add(
      NotificationCard(
        id: 'rank-pb-${pbAnnouncements.length}',
        tab: NotificationTab.forYou,
        entityName: 'CricUnity Rewards',
        title: pbAnnouncements.last,
        priority: NotificationPriority.p2,
        channel: NotificationChannel.rewards,
        actions: const [NotificationActionType.share],
        createdAt: now,
      ),
    );
  }
  return cards;
}

/// PRD §15 row: "Message received." Real read of [chatsProvider] --
/// this codebase now has a real messaging module (E15-05), closing
/// what was a genuine gap in E12-05's original pass.
List<NotificationCard> _messageCards(Ref ref, DateTime now) {
  final chats = ref.read(chatsProvider).chats;
  final cards = <NotificationCard>[];
  for (final chat in chats) {
    if (chat.unreadCount == 0) continue;
    final lastFromOther = chat.messages
        .where((m) => m.senderName != composerViewerName)
        .lastOrNull;
    cards.add(
      NotificationCard(
        id: 'message-received-${chat.id}-${chat.unreadCount}',
        tab: NotificationTab.forYou,
        entityName: chat.name,
        title: chat.unreadCount > 1
            ? '${chat.unreadCount} new messages from ${chat.name}'
            : (lastFromOther?.text ?? 'New message from ${chat.name}'),
        priority: chat.isMuted
            ? NotificationPriority.p2
            : NotificationPriority.p1,
        channel: NotificationChannel.social,
        actions: const [NotificationActionType.reply],
        createdAt: lastFromOther?.timestamp ?? now,
      ),
    );
  }
  return cards;
}

/// PRD §15 row: "Review reply." Real read of [reviewsProvider] -- only
/// fires for the viewer's own reviews that the ground owner has
/// replied to.
List<NotificationCard> _reviewReplyCards(Ref ref, DateTime now) {
  final reviews = ref.read(reviewsProvider).reviews;
  return [
    for (final r in reviews)
      if (r.reviewerName == composerViewerName && r.hasOwnerReply)
        NotificationCard(
          id: 'review-reply-${r.id}',
          tab: NotificationTab.forYou,
          entityName: r.groundId,
          title: 'The ground replied to your review: "${r.ownerReplyText}"',
          priority: NotificationPriority.p3,
          channel: NotificationChannel.bookings,
          actions: const [NotificationActionType.view],
          createdAt: r.ownerReplyAt ?? now,
        ),
  ];
}

/// PRD §15 catalog rows with no real backing data source in this
/// codebase: no "follow a match/player" relationship graph exists
/// anywhere (toss/innings/result live events for followed matches,
/// wicket/fifty-by-followed-player, new follower/mention/comment/
/// props), no received-team-invite-offers state exists (distinct from
/// join requests -- team_invite_provider.dart only tracks the
/// captain's outgoing link), no historical "old record holder" ledger
/// exists in the recognition module, and no cross-tournament Organizer
/// Score profile aggregates a challenge-overtaken style event.
/// Flagged and mocked here, same convention as every other missing-
/// backend gap this session, rather than fabricating the underlying
/// relationship data. (Message received and Review reply, previously
/// flagged here too, are now genuinely wired above -- E15-05's
/// messaging module and E9-04's reviews module didn't exist when
/// E12-05 first wrote this list.)
List<NotificationCard> _unwiredCatalogRows(DateTime now) {
  return [
    NotificationCard(
      id: 'mock-toss-done',
      tab: NotificationTab.following,
      entityName: 'Monsoon Cup',
      title: 'Toss done -- Strikers CC chose to bat',
      priority: NotificationPriority.p2,
      channel: NotificationChannel.matches,
      actions: const [NotificationActionType.view],
      createdAt: now.subtract(const Duration(hours: 3)),
    ),
    NotificationCard(
      id: 'mock-new-follower',
      tab: NotificationTab.forYou,
      entityName: 'Priya Nair',
      title: 'Priya Nair started following you',
      priority: NotificationPriority.p2,
      channel: NotificationChannel.social,
      actions: const [NotificationActionType.view],
      createdAt: now.subtract(const Duration(hours: 6)),
    ),
  ];
}
