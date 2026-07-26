import 'package:cricunity/teams/carpool_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('joinRide() adds the rider to a ride with a free seat', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(carpoolProvider.notifier);

    final error = notifier.joinRide('ride-1', 'Vikram Shah');

    expect(error, isNull);
    final ride = container
        .read(carpoolProvider)
        .rides
        .firstWhere((r) => r.id == 'ride-1');
    expect(ride.riders, contains('Vikram Shah'));
  });

  test('AC: joinRide() is rejected once the ride is full', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(carpoolProvider.notifier);

    // Mock ride-2 has capacity 2, already fully booked.
    final error = notifier.joinRide('ride-2', 'Vikram Shah');

    expect(error, isNotNull);
  });

  test('joinRide() twice for the same rider is rejected the second time', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(carpoolProvider.notifier);
    notifier.joinRide('ride-1', 'Vikram Shah');

    final error = notifier.joinRide('ride-1', 'Vikram Shah');

    expect(error, isNotNull);
  });

  test('leaveRide() frees the seat back up', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(carpoolProvider.notifier);

    notifier.leaveRide('ride-1', 'Priya Nair');

    final ride = container
        .read(carpoolProvider)
        .rides
        .firstWhere((r) => r.id == 'ride-1');
    expect(ride.riders, isNot(contains('Priya Nair')));
  });

  test('fuelSplitSuggestion divides the cost across driver + riders', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // ride-1: fuelCost 400, 1 rider -> split across driver+rider (2).
    final ride = container
        .read(carpoolProvider)
        .rides
        .firstWhere((r) => r.id == 'ride-1');
    expect(ride.fuelSplitSuggestion, 200);
  });
}
