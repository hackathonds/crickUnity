import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'economy_console_models.dart';

/// Reuses the app's recurring mock identities (club_provider.dart,
/// avatar_screen.dart) as the two Super Admins needed to demonstrate
/// dual-control co-sign, rather than inventing new ones.
const List<String> superAdminNames = ['Deepak Sharma', 'Priya Nair'];

class EconomyConsoleState {
  final List<EarningRule> earningRules;
  final List<FeePolicy> feePolicies;
  final List<PendingRateChange> pendingRateChanges;
  final List<PendingFeeChange> pendingFeeChanges;
  final List<FeatureFlag> featureFlags;
  final List<ChangelogEntry> changelog;
  final List<String> adminAccounts;
  final PlatformStatusLevel statusLevel;
  final String statusMessage;

  const EconomyConsoleState({
    this.earningRules = canonicalEarningRules,
    this.feePolicies = defaultFeePolicies,
    this.pendingRateChanges = const [],
    this.pendingFeeChanges = const [],
    this.featureFlags = defaultFeatureFlags,
    this.changelog = const [],
    this.adminAccounts = const ['Admin'],
    this.statusLevel = PlatformStatusLevel.operational,
    this.statusMessage = '',
  });

  EconomyConsoleState copyWith({
    List<EarningRule>? earningRules,
    List<FeePolicy>? feePolicies,
    List<PendingRateChange>? pendingRateChanges,
    List<PendingFeeChange>? pendingFeeChanges,
    List<FeatureFlag>? featureFlags,
    List<ChangelogEntry>? changelog,
    List<String>? adminAccounts,
    PlatformStatusLevel? statusLevel,
    String? statusMessage,
  }) {
    return EconomyConsoleState(
      earningRules: earningRules ?? this.earningRules,
      feePolicies: feePolicies ?? this.feePolicies,
      pendingRateChanges: pendingRateChanges ?? this.pendingRateChanges,
      pendingFeeChanges: pendingFeeChanges ?? this.pendingFeeChanges,
      featureFlags: featureFlags ?? this.featureFlags,
      changelog: changelog ?? this.changelog,
      adminAccounts: adminAccounts ?? this.adminAccounts,
      statusLevel: statusLevel ?? this.statusLevel,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

/// PRD §2.17 -- Super Admin's economy/governance console (E16-12,
/// unblocked by E16-11's Admin console).
class EconomyConsoleNotifier extends Notifier<EconomyConsoleState> {
  @override
  EconomyConsoleState build() => const EconomyConsoleState();

  void proposeRateChange({
    required String ruleAction,
    required int proposedCoins,
    required int proposedXp,
    required String proposedBy,
    DateTime Function() now = DateTime.now,
  }) {
    final rule = state.earningRules.firstWhere((r) => r.action == ruleAction);
    state = state.copyWith(
      pendingRateChanges: [
        ...state.pendingRateChanges,
        PendingRateChange(
          id: 'rate-${now().microsecondsSinceEpoch}',
          ruleAction: ruleAction,
          currentCoins: rule.coins,
          currentXp: rule.xp,
          proposedCoins: proposedCoins,
          proposedXp: proposedXp,
          proposedBy: proposedBy,
          proposedAt: now(),
        ),
      ],
    );
  }

  /// PRD §2.17: "Dual-control for economy changes (second Super Admin
  /// co-sign)." Returns false (no state change) if [coSignerName] is
  /// the same person who proposed it.
  bool coSignRateChange(
    String changeId, {
    required String coSignerName,
    DateTime Function() now = DateTime.now,
  }) {
    final change = state.pendingRateChanges
        .where((c) => c.id == changeId)
        .firstOrNull;
    if (change == null || change.proposedBy == coSignerName) return false;

    state = state.copyWith(
      earningRules: [
        for (final r in state.earningRules)
          if (r.action == change.ruleAction)
            r.copyWith(coins: change.proposedCoins, xp: change.proposedXp)
          else
            r,
      ],
      pendingRateChanges: state.pendingRateChanges
          .where((c) => c.id != changeId)
          .toList(),
      changelog: [
        ChangelogEntry(
          id: 'log-${now().microsecondsSinceEpoch}',
          title: '${change.ruleAction} rate updated',
          description:
              'Coins ${change.currentCoins} -> ${change.proposedCoins}, '
              'XP ${change.currentXp} -> ${change.proposedXp}. '
              'Co-signed by ${change.proposedBy} and $coSignerName.',
          publishedAt: now(),
        ),
        ...state.changelog,
      ],
    );
    return true;
  }

  void proposeFeeChange({
    required String feeName,
    required double proposedPercent,
    required String proposedBy,
    DateTime Function() now = DateTime.now,
  }) {
    final fee = state.feePolicies.firstWhere((f) => f.name == feeName);
    state = state.copyWith(
      pendingFeeChanges: [
        ...state.pendingFeeChanges,
        PendingFeeChange(
          id: 'fee-${now().microsecondsSinceEpoch}',
          feeName: feeName,
          currentPercent: fee.percent,
          proposedPercent: proposedPercent,
          proposedBy: proposedBy,
          proposedAt: now(),
        ),
      ],
    );
  }

  bool coSignFeeChange(
    String changeId, {
    required String coSignerName,
    DateTime Function() now = DateTime.now,
  }) {
    final change = state.pendingFeeChanges
        .where((c) => c.id == changeId)
        .firstOrNull;
    if (change == null || change.proposedBy == coSignerName) return false;

    state = state.copyWith(
      feePolicies: [
        for (final f in state.feePolicies)
          if (f.name == change.feeName)
            f.copyWith(percent: change.proposedPercent)
          else
            f,
      ],
      pendingFeeChanges: state.pendingFeeChanges
          .where((c) => c.id != changeId)
          .toList(),
      changelog: [
        ChangelogEntry(
          id: 'log-${now().microsecondsSinceEpoch}',
          title: '${change.feeName} updated',
          description:
              '${change.currentPercent}% -> ${change.proposedPercent}%. '
              'Co-signed by ${change.proposedBy} and $coSignerName.',
          publishedAt: now(),
        ),
        ...state.changelog,
      ],
    );
    return true;
  }

  void toggleFeatureFlagRegion(String flagKey, String region) {
    state = state.copyWith(
      featureFlags: [
        for (final f in state.featureFlags)
          if (f.key == flagKey)
            f.copyWith(enabledRegions: {...f.enabledRegions}..toggle(region))
          else
            f,
      ],
    );
  }

  void addAdmin(String name) {
    if (state.adminAccounts.contains(name)) return;
    state = state.copyWith(adminAccounts: [...state.adminAccounts, name]);
  }

  void removeAdmin(String name) {
    state = state.copyWith(
      adminAccounts: state.adminAccounts.where((a) => a != name).toList(),
    );
  }

  void setStatusBanner(PlatformStatusLevel level, String message) {
    state = state.copyWith(statusLevel: level, statusMessage: message);
  }
}

extension _ToggleSet<T> on Set<T> {
  void toggle(T value) {
    if (!remove(value)) add(value);
  }
}

final economyConsoleProvider =
    NotifierProvider<EconomyConsoleNotifier, EconomyConsoleState>(
      EconomyConsoleNotifier.new,
    );
