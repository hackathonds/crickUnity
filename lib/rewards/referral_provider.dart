import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'referral_models.dart';
import 'rewards_models.dart';
import 'rewards_provider.dart';

class ReferralState {
  final String code;
  final List<ReferralEntry> referrals;

  const ReferralState({
    this.code = 'CRICU-DEEPAK42',
    this.referrals = const [],
  });

  ReferralState copyWith({String? code, List<ReferralEntry>? referrals}) {
    return ReferralState(
      code: code ?? this.code,
      referrals: referrals ?? this.referrals,
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'referrals': [for (final r in referrals) r.toJson()],
  };

  factory ReferralState.fromJson(Map<String, dynamic> json) {
    return ReferralState(
      code: json['code'] as String,
      referrals: [
        for (final r in json['referrals'] as List)
          ReferralEntry.fromJson(r as Map<String, dynamic>),
      ],
    );
  }
}

/// PRD §13.1 -- E6-07's referral engine. No real invite/contacts/SMS
/// pipeline exists -- "invite" here is a mock join, same
/// flagged-mock convention as every other missing-integration gap.
class ReferralNotifier extends PersistedNotifier<ReferralState> {
  @override
  String get persistenceKey => 'referral_v1';

  @override
  ReferralState seed() => const ReferralState();

  @override
  Map<String, dynamic> toJson(ReferralState value) => value.toJson();

  @override
  ReferralState fromJson(Map<String, dynamic> json) =>
      ReferralState.fromJson(json);

  void inviteFriend(String name, {DateTime Function() now = DateTime.now}) {
    final entry = ReferralEntry(
      id: 'referral-${now().microsecondsSinceEpoch}',
      name: name,
      status: ReferralStatus.joined,
      joinedAt: now(),
    );
    state = state.copyWith(referrals: [...state.referrals, entry]);
  }

  /// Only the referrer is a concrete account this app can credit --
  /// referee-side crediting (their 50/50) is log-only, same
  /// scoped-identity convention as the match ripple (E4-10/E6-01).
  void markFirstVerifiedMatch(String entryId) {
    final index = state.referrals.indexWhere((r) => r.id == entryId);
    if (index < 0) return;
    final entry = state.referrals[index];
    if (entry.status == ReferralStatus.firstMatchVerified) return;

    final updated = [...state.referrals];
    updated[index] = entry.copyWith(status: ReferralStatus.firstMatchVerified);
    state = state.copyWith(referrals: updated);

    ref.read(rewardsProvider.notifier).awardActions(const [
      EarningAction.referral,
    ], contextLabel: '${entry.name} played their first verified match');
  }
}

final referralProvider = NotifierProvider<ReferralNotifier, ReferralState>(
  ReferralNotifier.new,
);
