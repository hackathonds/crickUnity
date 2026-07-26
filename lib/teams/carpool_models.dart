/// Backlog cites "PRD G.13" for Carpool/Duty Roster/Kit Inventory/
/// Documents -- no such section exists anywhere in the PRD (it has no
/// "G." numbering at all), same class of gap as the missing Appendix D
/// (E2-05) and Appendix E (E3-07) citations. Proceeded on the backlog's
/// own concrete inline description ("seat pips + fuel-split suggestion")
/// plus DS §7 screen 18's wording ("Carpool cards show seats pips
/// (● ● ○), Join → confirm").
class CarpoolRide {
  final String id;
  final String driverName;
  final String destination;
  final int seatCapacity;
  final List<String> riders;
  final int fuelCostRupees;

  const CarpoolRide({
    required this.id,
    required this.driverName,
    required this.destination,
    required this.seatCapacity,
    this.riders = const [],
    required this.fuelCostRupees,
  });

  int get seatsFilled => riders.length;
  int get seatsAvailable => seatCapacity - seatsFilled;
  bool get isFull => seatsAvailable <= 0;

  /// A per-rider suggestion, not a real expense-ledger write -- no
  /// expense-splitting backend exists yet (same precedent as the Jersey
  /// board's pricePerMember(), E3-09).
  int get fuelSplitSuggestion =>
      riders.isEmpty ? fuelCostRupees : fuelCostRupees ~/ (riders.length + 1);

  CarpoolRide copyWith({List<String>? riders}) {
    return CarpoolRide(
      id: id,
      driverName: driverName,
      destination: destination,
      seatCapacity: seatCapacity,
      riders: riders ?? this.riders,
      fuelCostRupees: fuelCostRupees,
    );
  }
}

/// Mock data for the debug demo and tests -- no backend carpool service
/// exists yet.
List<CarpoolRide> mockCarpoolRides() => const [
  CarpoolRide(
    id: 'ride-1',
    driverName: 'Arjun Rao',
    destination: 'Deccan Gymkhana',
    seatCapacity: 3,
    riders: ['Priya Nair'],
    fuelCostRupees: 400,
  ),
  CarpoolRide(
    id: 'ride-2',
    driverName: 'Kabir Singh',
    destination: 'Deccan Gymkhana',
    seatCapacity: 2,
    riders: ['Ananya Iyer', 'Farhan Ali'],
    fuelCostRupees: 300,
  ),
];
