import 'expense_models.dart';

enum AutoSplitBundleStatus { draft, finalized, voided }

/// PRD §11.4: "Match creation spawns a draft expense bundle from the
/// team's preset (ground+ball+officials). At match confirmation, bundle
/// finalizes against the final squad: marked-unavailable players
/// auto-excluded; last-minute replacements auto-included; MVP-exempt
/// rule applied if team enabled it."
class AutoSplitBundle {
  final String matchId;
  final int groundFee;
  final int ballFee;
  final int officialsFee;
  final AutoSplitBundleStatus status;
  final SplitMethod splitMethod;
  final bool mvpExemptEnabled;
  final String? mvpName;
  final List<String> replacementNames;
  final List<String> notificationLog;
  final String? voidReason;
  final String? expenseId;

  const AutoSplitBundle({
    required this.matchId,
    required this.groundFee,
    required this.ballFee,
    required this.officialsFee,
    this.status = AutoSplitBundleStatus.draft,
    this.splitMethod = SplitMethod.equal,
    this.mvpExemptEnabled = false,
    this.mvpName,
    this.replacementNames = const [],
    this.notificationLog = const [],
    this.voidReason,
    this.expenseId,
  });

  int get totalRupees => groundFee + ballFee + officialsFee;

  AutoSplitBundle copyWith({
    AutoSplitBundleStatus? status,
    SplitMethod? splitMethod,
    bool? mvpExemptEnabled,
    String? mvpName,
    bool clearMvpName = false,
    List<String>? replacementNames,
    List<String>? notificationLog,
    String? voidReason,
    String? expenseId,
  }) {
    return AutoSplitBundle(
      matchId: matchId,
      groundFee: groundFee,
      ballFee: ballFee,
      officialsFee: officialsFee,
      status: status ?? this.status,
      splitMethod: splitMethod ?? this.splitMethod,
      mvpExemptEnabled: mvpExemptEnabled ?? this.mvpExemptEnabled,
      mvpName: clearMvpName ? null : (mvpName ?? this.mvpName),
      replacementNames: replacementNames ?? this.replacementNames,
      notificationLog: notificationLog ?? this.notificationLog,
      voidReason: voidReason ?? this.voidReason,
      expenseId: expenseId ?? this.expenseId,
    );
  }
}
