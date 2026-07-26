import 'package:cricunity/teams/edit_team_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts clean: not dirty, no former name active', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(editTeamProvider);

    expect(state.isDirty, isFalse);
    expect(state.formerNameActive(), isFalse);
  });

  test('editing city marks the form dirty and savable', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editTeamProvider.notifier);

    notifier.setCity('Mumbai');

    final state = container.read(editTeamProvider);
    expect(state.isDirty, isTrue);
    expect(state.canSave, isTrue);
  });

  test('AC: saving a name change logs the entry and starts the 90-day '
      '"formerly known as" window', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editTeamProvider.notifier);
    final originalName = container.read(editTeamProvider).baseline.name;
    final fixedNow = DateTime(2026, 1, 1);

    notifier.setName('New Name CC');
    final result = notifier.save(now: () => fixedNow);

    expect(result, isTrue);
    final state = container.read(editTeamProvider);
    expect(state.baseline.changeLog, hasLength(1));
    expect(state.baseline.changeLog.single.field, 'name');
    expect(state.baseline.changeLog.single.from, originalName);
    expect(state.baseline.changeLog.single.to, 'New Name CC');
    expect(state.baseline.formerName, originalName);
    expect(
      state.baseline.formerNameExpiresAt,
      fixedNow.add(const Duration(days: formerNameWindowDays)),
    );
    expect(state.formerNameActive(now: () => fixedNow), isTrue);
  });

  test('the "formerly known as" window expires after 90 days', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editTeamProvider.notifier);
    final fixedNow = DateTime(2026, 1, 1);
    notifier.setName('New Name CC');
    notifier.save(now: () => fixedNow);

    final state = container.read(editTeamProvider);
    final wayAfter = fixedNow.add(const Duration(days: 91));

    expect(state.formerNameActive(now: () => wayAfter), isFalse);
  });

  test('saving without a name change does not touch the change log', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editTeamProvider.notifier);

    notifier.setCity('Mumbai');
    notifier.save();

    expect(container.read(editTeamProvider).baseline.changeLog, isEmpty);
  });

  test('discard() reverts in-progress edits back to the baseline', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editTeamProvider.notifier);
    final originalCity = container.read(editTeamProvider).baseline.city;

    notifier.setCity('Mumbai');
    notifier.discard();

    final state = container.read(editTeamProvider);
    expect(state.city, originalCity);
    expect(state.isDirty, isFalse);
  });

  test('canSave is false once every format is deselected', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editTeamProvider.notifier);
    final baselineFormats = container
        .read(editTeamProvider)
        .formatFocus
        .toList();

    for (final format in baselineFormats) {
      notifier.toggleFormat(format);
    }

    expect(container.read(editTeamProvider).formatFocus, isEmpty);
    expect(container.read(editTeamProvider).canSave, isFalse);
  });
}
