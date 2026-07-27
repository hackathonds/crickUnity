import 'package:flutter_riverpod/flutter_riverpod.dart';

/// PRD §13.6 ("CricUnity Pro") + DS §11.14 ("Family = manage-members
/// screen, 4 slots"). No PRD text distinguishes a separate "Family"
/// price tier from solo Pro beyond DS naming both on one paywall --
/// modeled as 2 subscribable plans, Family being Pro-plus-4-slots, a
/// flagged judgment call.
enum PremiumPlan { none, pro, family }

const int familySlotCount = 4;

class PremiumState {
  final PremiumPlan plan;
  final List<String?> familySlots;
  final List<bool> guardianBundleBySlot;

  const PremiumState({
    this.plan = PremiumPlan.none,
    this.familySlots = const [null, null, null, null],
    this.guardianBundleBySlot = const [false, false, false, false],
  });

  /// PRD §13.6: "1.25x coin multiplier (capped)." Family includes every
  /// Pro perk, so both plans count as "Pro" for that multiplier.
  bool get isPro => plan != PremiumPlan.none;

  PremiumState copyWith({
    PremiumPlan? plan,
    List<String?>? familySlots,
    List<bool>? guardianBundleBySlot,
  }) {
    return PremiumState(
      plan: plan ?? this.plan,
      familySlots: familySlots ?? this.familySlots,
      guardianBundleBySlot: guardianBundleBySlot ?? this.guardianBundleBySlot,
    );
  }
}

/// PRD §13.6's "Rule: Pro never affects rankings, Trust, or
/// verification -- competitive integrity is unbuyable." This notifier
/// only ever gates the coin multiplier and Family slots -- nothing here
/// touches ranking/Trust/verification state anywhere in the codebase.
class PremiumNotifier extends Notifier<PremiumState> {
  @override
  PremiumState build() => const PremiumState();

  void subscribe(PremiumPlan plan) {
    state = state.copyWith(plan: plan);
  }

  void cancel() {
    state = const PremiumState();
  }

  void inviteFamilyMember(int slotIndex, String name) {
    if (state.plan != PremiumPlan.family) return;
    final slots = [...state.familySlots];
    slots[slotIndex] = name;
    state = state.copyWith(familySlots: slots);
  }

  void removeFamilyMember(int slotIndex) {
    final slots = [...state.familySlots];
    slots[slotIndex] = null;
    final bundles = [...state.guardianBundleBySlot];
    bundles[slotIndex] = false;
    state = state.copyWith(familySlots: slots, guardianBundleBySlot: bundles);
  }

  void setGuardianBundle(int slotIndex, bool value) {
    final bundles = [...state.guardianBundleBySlot];
    bundles[slotIndex] = value;
    state = state.copyWith(guardianBundleBySlot: bundles);
  }
}

final premiumProvider = NotifierProvider<PremiumNotifier, PremiumState>(
  PremiumNotifier.new,
);
