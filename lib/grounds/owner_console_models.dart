/// PRD §10.6 (Owner Dashboard): "Maintenance: block slots with reason
/// (public sees 'Maintenance'); recurring blocks. Staff: caretaker
/// sub-accounts (check-in/no-show marking only; no pricing/finance)."
class MaintenanceBlock {
  final String id;
  final String groundId;
  final DateTime slotStart;
  final String reason;
  final bool recurringWeekly;

  const MaintenanceBlock({
    required this.id,
    required this.groundId,
    required this.slotStart,
    required this.reason,
    this.recurringWeekly = false,
  });

  /// Recurring blocks repeat on the same weekday+hour every week.
  bool coversSlot(String groundId, DateTime slot) {
    if (this.groundId != groundId) return false;
    if (!recurringWeekly) return slotStart == slot;
    return slotStart.weekday == slot.weekday && slotStart.hour == slot.hour;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'groundId': groundId,
    'slotStart': slotStart.toIso8601String(),
    'reason': reason,
    'recurringWeekly': recurringWeekly,
  };

  factory MaintenanceBlock.fromJson(Map<String, dynamic> json) {
    return MaintenanceBlock(
      id: json['id'] as String,
      groundId: json['groundId'] as String,
      slotStart: DateTime.parse(json['slotStart'] as String),
      reason: json['reason'] as String,
      recurringWeekly: json['recurringWeekly'] as bool? ?? false,
    );
  }
}

/// PRD §2.11: "staff sub-accounts (caretaker: check-in powers only)."
/// No multi-account auth system exists (same flagged convention as
/// every other cross-party flow this session) -- a caretaker is
/// modeled as a named entry the owner manages, not a real login.
class CaretakerAccount {
  final String id;
  final String name;

  const CaretakerAccount({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory CaretakerAccount.fromJson(Map<String, dynamic> json) {
    return CaretakerAccount(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}
