/// PRD §11.8: "payouts above threshold need dual approval (Captain+
/// Manager or Owner)."
class WalletPayoutRequest {
  final String id;
  final String purpose;
  final int amount;
  final bool captainApproved;
  final bool managerOrOwnerApproved;
  final bool completed;
  final String? expenseId;

  const WalletPayoutRequest({
    required this.id,
    required this.purpose,
    required this.amount,
    this.captainApproved = false,
    this.managerOrOwnerApproved = false,
    this.completed = false,
    this.expenseId,
  });

  WalletPayoutRequest copyWith({
    bool? captainApproved,
    bool? managerOrOwnerApproved,
    bool? completed,
    String? expenseId,
  }) {
    return WalletPayoutRequest(
      id: id,
      purpose: purpose,
      amount: amount,
      captainApproved: captainApproved ?? this.captainApproved,
      managerOrOwnerApproved:
          managerOrOwnerApproved ?? this.managerOrOwnerApproved,
      completed: completed ?? this.completed,
      expenseId: expenseId ?? this.expenseId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'purpose': purpose,
    'amount': amount,
    'captainApproved': captainApproved,
    'managerOrOwnerApproved': managerOrOwnerApproved,
    'completed': completed,
    'expenseId': expenseId,
  };

  factory WalletPayoutRequest.fromJson(Map<String, dynamic> json) {
    return WalletPayoutRequest(
      id: json['id'] as String,
      purpose: json['purpose'] as String,
      amount: json['amount'] as int,
      captainApproved: json['captainApproved'] as bool? ?? false,
      managerOrOwnerApproved: json['managerOrOwnerApproved'] as bool? ?? false,
      completed: json['completed'] as bool? ?? false,
      expenseId: json['expenseId'] as String?,
    );
  }
}
