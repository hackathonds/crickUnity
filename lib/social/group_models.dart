import 'composer_screen.dart';

/// PRD §12.5: "Groups: interest communities ... public/private/hidden;
/// admin/mod roles; join questions; rules pinned; post approval toggle;
/// group events & polls; member list privacy per settings."
enum GroupPrivacy { public, private, hidden }

const Map<GroupPrivacy, String> groupPrivacyLabels = {
  GroupPrivacy.public: 'Public',
  GroupPrivacy.private: 'Private',
  GroupPrivacy.hidden: 'Hidden',
};

class GroupJoinRequest {
  final String requesterName;
  final List<String> answers;

  const GroupJoinRequest({required this.requesterName, required this.answers});
}

class GroupPost {
  final String id;
  final String authorName;
  final String body;
  final DateTime timestamp;
  final bool approved;

  const GroupPost({
    required this.id,
    required this.authorName,
    required this.body,
    required this.timestamp,
    this.approved = false,
  });

  GroupPost copyWith({bool? approved}) => GroupPost(
    id: id,
    authorName: authorName,
    body: body,
    timestamp: timestamp,
    approved: approved ?? this.approved,
  );
}

class Group {
  final String id;
  final String name;
  final String description;
  final GroupPrivacy privacy;
  final List<String> joinQuestions;
  final List<String> rules;
  final bool postApprovalRequired;
  final bool memberListVisibleToPublic;
  final List<String> memberNames;
  final List<String> adminNames;
  final List<String> modNames;
  final List<GroupJoinRequest> pendingJoinRequests;
  final List<GroupPost> posts;

  const Group({
    required this.id,
    required this.name,
    required this.description,
    required this.privacy,
    this.joinQuestions = const [],
    this.rules = const [],
    this.postApprovalRequired = false,
    this.memberListVisibleToPublic = true,
    this.memberNames = const [],
    this.adminNames = const [],
    this.modNames = const [],
    this.pendingJoinRequests = const [],
    this.posts = const [],
  });

  bool get viewerIsMember => memberNames.contains(composerViewerName);
  bool get viewerIsAdminOrMod =>
      adminNames.contains(composerViewerName) ||
      modNames.contains(composerViewerName);
  List<GroupPost> get approvedPosts => posts.where((p) => p.approved).toList();

  Group copyWith({
    bool? postApprovalRequired,
    bool? memberListVisibleToPublic,
    List<String>? memberNames,
    List<String>? modNames,
    List<GroupJoinRequest>? pendingJoinRequests,
    List<GroupPost>? posts,
  }) {
    return Group(
      id: id,
      name: name,
      description: description,
      privacy: privacy,
      joinQuestions: joinQuestions,
      rules: rules,
      postApprovalRequired: postApprovalRequired ?? this.postApprovalRequired,
      memberListVisibleToPublic:
          memberListVisibleToPublic ?? this.memberListVisibleToPublic,
      memberNames: memberNames ?? this.memberNames,
      adminNames: adminNames,
      modNames: modNames ?? this.modNames,
      pendingJoinRequests: pendingJoinRequests ?? this.pendingJoinRequests,
      posts: posts ?? this.posts,
    );
  }
}
