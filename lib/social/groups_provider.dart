import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'composer_screen.dart';
import 'group_models.dart';

class GroupsState {
  final List<Group> groups;

  const GroupsState({this.groups = const []});

  Group? groupById(String id) {
    for (final g in groups) {
      if (g.id == id) return g;
    }
    return null;
  }

  GroupsState copyWith({List<Group>? groups}) =>
      GroupsState(groups: groups ?? this.groups);

  Map<String, dynamic> toJson() => {
    'groups': [for (final g in groups) g.toJson()],
  };

  factory GroupsState.fromJson(Map<String, dynamic> json) {
    return GroupsState(
      groups: [
        for (final g in json['groups'] as List)
          Group.fromJson(g as Map<String, dynamic>),
      ],
    );
  }
}

/// PRD §12.5 -- E7-06's Groups engine.
class GroupsNotifier extends PersistedNotifier<GroupsState> {
  @override
  String get persistenceKey => 'groups_v1';

  @override
  GroupsState seed() => GroupsState(groups: _seedGroups());

  @override
  Map<String, dynamic> toJson(GroupsState value) => value.toJson();

  @override
  GroupsState fromJson(Map<String, dynamic> json) => GroupsState.fromJson(json);

  static List<Group> _seedGroups() => [
    const Group(
      id: 'group-tennis-ball',
      name: 'North Delhi Tennis-ball Cricket',
      description: 'Weekend tennis-ball games and meetups.',
      privacy: GroupPrivacy.public,
      rules: ['Be respectful', 'No spam'],
      memberNames: ['Arjun Rao', 'Priya Nair'],
      adminNames: ['Arjun Rao'],
    ),
    const Group(
      id: 'group-scorers',
      name: 'Verified Scorers Guild',
      description: 'For scorers to share tips and gigs.',
      privacy: GroupPrivacy.private,
      joinQuestions: ['How many matches have you scored?'],
      postApprovalRequired: true,
      memberListVisibleToPublic: false,
      memberNames: ['Deepak Sharma'],
      adminNames: ['Deepak Sharma'],
    ),
  ];

  void requestToJoin(String groupId, List<String> answers) {
    _update(groupId, (g) {
      if (g.privacy == GroupPrivacy.public) {
        return g.copyWith(memberNames: [...g.memberNames, composerViewerName]);
      }
      return g.copyWith(
        pendingJoinRequests: [
          ...g.pendingJoinRequests,
          GroupJoinRequest(requesterName: composerViewerName, answers: answers),
        ],
      );
    });
  }

  /// Caller (group_detail_screen.dart) only shows this to
  /// `group.viewerIsAdminOrMod`.
  void approveJoinRequest(String groupId, String requesterName) {
    _update(groupId, (g) {
      return g.copyWith(
        memberNames: [...g.memberNames, requesterName],
        pendingJoinRequests: g.pendingJoinRequests
            .where((r) => r.requesterName != requesterName)
            .toList(),
      );
    });
  }

  void denyJoinRequest(String groupId, String requesterName) {
    _update(groupId, (g) {
      return g.copyWith(
        pendingJoinRequests: g.pendingJoinRequests
            .where((r) => r.requesterName != requesterName)
            .toList(),
      );
    });
  }

  void leaveGroup(String groupId) {
    _update(
      groupId,
      (g) => g.copyWith(
        memberNames: g.memberNames
            .where((n) => n != composerViewerName)
            .toList(),
      ),
    );
  }

  void toggleModRole(String groupId, String memberName) {
    _update(groupId, (g) {
      final isMod = g.modNames.contains(memberName);
      return g.copyWith(
        modNames: isMod
            ? g.modNames.where((n) => n != memberName).toList()
            : [...g.modNames, memberName],
      );
    });
  }

  void setPostApprovalRequired(String groupId, bool required) {
    _update(groupId, (g) => g.copyWith(postApprovalRequired: required));
  }

  void setMemberListVisibility(String groupId, bool visible) {
    _update(groupId, (g) => g.copyWith(memberListVisibleToPublic: visible));
  }

  /// PRD: "post approval toggle." Admin/mod posts always go live; a
  /// regular member's post queues for approval when the toggle is on.
  void createPost(String groupId, String body) {
    _update(groupId, (g) {
      final autoApproved = !g.postApprovalRequired || g.viewerIsAdminOrMod;
      final post = GroupPost(
        id: 'grouppost-${DateTime.now().microsecondsSinceEpoch}',
        authorName: composerViewerName,
        body: body,
        timestamp: DateTime.now(),
        approved: autoApproved,
      );
      return g.copyWith(posts: [...g.posts, post]);
    });
  }

  void approvePost(String groupId, String postId) {
    _update(groupId, (g) {
      return g.copyWith(
        posts: [
          for (final p in g.posts)
            if (p.id == postId) p.copyWith(approved: true) else p,
        ],
      );
    });
  }

  void rejectPost(String groupId, String postId) {
    _update(
      groupId,
      (g) => g.copyWith(posts: g.posts.where((p) => p.id != postId).toList()),
    );
  }

  void _update(String groupId, Group Function(Group) transform) {
    state = state.copyWith(
      groups: [
        for (final g in state.groups)
          if (g.id == groupId) transform(g) else g,
      ],
    );
  }
}

final groupsProvider = NotifierProvider<GroupsNotifier, GroupsState>(
  GroupsNotifier.new,
);
