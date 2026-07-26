import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'announcement_models.dart';
import 'team_member_models.dart';

class AnnouncementsState {
  final List<Announcement> announcements;

  const AnnouncementsState({this.announcements = const []});

  AnnouncementsState copyWith({List<Announcement>? announcements}) {
    return AnnouncementsState(
      announcements: announcements ?? this.announcements,
    );
  }
}

/// PRD §6.8: "Captain/VC/Manager post announcements" -- Owner included
/// too since §2.9 grants Owner "everything Captain has."
const Set<TeamMemberRole> _canPostAnnouncements = {
  TeamMemberRole.captain,
  TeamMemberRole.viceCaptain,
  TeamMemberRole.manager,
  TeamMemberRole.owner,
};

class AnnouncementsNotifier extends Notifier<AnnouncementsState> {
  @override
  AnnouncementsState build() =>
      AnnouncementsState(announcements: mockAnnouncements());

  /// Returns null on success; a human-readable denial reason otherwise
  /// (never mutates state in that case).
  String? post({
    required String body,
    required String actorName,
    required TeamMemberRole actingRole,
    required int totalMembers,
    bool isPushPriority = false,
    bool commentsEnabled = true,
    DateTime Function() now = DateTime.now,
  }) {
    if (!_canPostAnnouncements.contains(actingRole)) {
      return "You don't have permission to post announcements.";
    }
    if (body.trim().isEmpty) {
      return 'Write something before posting.';
    }
    if (isPushPriority) {
      final lastPushPriority = state.announcements
          .where((a) => a.isPushPriority)
          .map((a) => a.postedAt)
          .fold<DateTime?>(
            null,
            (latest, postedAt) =>
                latest == null || postedAt.isAfter(latest) ? postedAt : latest,
          );
      if (lastPushPriority != null &&
          now().difference(lastPushPriority).inHours <
              pushPriorityCooldownHours) {
        return 'Only 1 push-priority announcement is allowed every '
            '$pushPriorityCooldownHours hours.';
      }
    }

    state = state.copyWith(
      announcements: [
        Announcement(
          id: 'ann-${now().millisecondsSinceEpoch}',
          authorName: actorName,
          body: body.trim(),
          postedAt: now(),
          isPushPriority: isPushPriority,
          commentsEnabled: commentsEnabled,
          totalMembers: totalMembers,
        ),
        ...state.announcements,
      ],
    );
    return null;
  }

  void toggleComments(String id) {
    state = state.copyWith(
      announcements: [
        for (final a in state.announcements)
          if (a.id == id)
            a.copyWith(commentsEnabled: !a.commentsEnabled)
          else
            a,
      ],
    );
  }

  void markSeen(String id, String memberName) {
    state = state.copyWith(
      announcements: [
        for (final a in state.announcements)
          if (a.id == id) a.copyWith(seenBy: {...a.seenBy, memberName}) else a,
      ],
    );
  }
}

final announcementsProvider =
    NotifierProvider<AnnouncementsNotifier, AnnouncementsState>(
      AnnouncementsNotifier.new,
    );
