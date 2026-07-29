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

  Map<String, dynamic> toJson() => {
    'requesterName': requesterName,
    'answers': answers,
  };

  factory GroupJoinRequest.fromJson(Map<String, dynamic> json) {
    return GroupJoinRequest(
      requesterName: json['requesterName'] as String,
      answers: [for (final a in json['answers'] as List) a as String],
    );
  }
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorName': authorName,
    'body': body,
    'timestamp': timestamp.toIso8601String(),
    'approved': approved,
  };

  factory GroupPost.fromJson(Map<String, dynamic> json) {
    return GroupPost(
      id: json['id'] as String,
      authorName: json['authorName'] as String,
      body: json['body'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      approved: json['approved'] as bool? ?? false,
    );
  }
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'privacy': privacy.name,
    'joinQuestions': joinQuestions,
    'rules': rules,
    'postApprovalRequired': postApprovalRequired,
    'memberListVisibleToPublic': memberListVisibleToPublic,
    'memberNames': memberNames,
    'adminNames': adminNames,
    'modNames': modNames,
    'pendingJoinRequests': [for (final r in pendingJoinRequests) r.toJson()],
    'posts': [for (final p in posts) p.toJson()],
  };

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      privacy: GroupPrivacy.values.byName(json['privacy'] as String),
      joinQuestions: [
        for (final q in json['joinQuestions'] as List) q as String,
      ],
      rules: [for (final r in json['rules'] as List) r as String],
      postApprovalRequired: json['postApprovalRequired'] as bool? ?? false,
      memberListVisibleToPublic:
          json['memberListVisibleToPublic'] as bool? ?? true,
      memberNames: [for (final n in json['memberNames'] as List) n as String],
      adminNames: [for (final n in json['adminNames'] as List) n as String],
      modNames: [for (final n in json['modNames'] as List) n as String],
      pendingJoinRequests: [
        for (final r in json['pendingJoinRequests'] as List)
          GroupJoinRequest.fromJson(r as Map<String, dynamic>),
      ],
      posts: [
        for (final p in json['posts'] as List)
          GroupPost.fromJson(p as Map<String, dynamic>),
      ],
    );
  }
}
