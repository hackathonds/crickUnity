import 'package:cricunity/profile/edit_profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts clean: not dirty, full name-change budget', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(editProfileProvider);

    expect(state.isDirty, isFalse);
    expect(state.nameChangesRemaining, maxNameChangesPerYear);
    expect(state.canSave, isFalse);
  });

  test('editing a field marks the form dirty and savable', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editProfileProvider.notifier);

    notifier.setCity('Mumbai');

    final state = container.read(editProfileProvider);
    expect(state.isDirty, isTrue);
    expect(state.canSave, isTrue);
  });

  test('save() commits edits, clears dirty, and re-baselines', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editProfileProvider.notifier);
    notifier.setCity('Mumbai');

    final result = notifier.save();

    expect(result, isTrue);
    final state = container.read(editProfileProvider);
    expect(state.isDirty, isFalse);
    expect(state.baseline.city, 'Mumbai');
    expect(state.saved, isTrue);
  });

  test('discard() reverts in-progress edits back to the baseline', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editProfileProvider.notifier);
    final originalCity = container.read(editProfileProvider).baseline.city;
    notifier.setCity('Mumbai');

    notifier.discard();

    final state = container.read(editProfileProvider);
    expect(state.city, originalCity);
    expect(state.isDirty, isFalse);
  });

  test('a name change logs an entry and consumes the yearly budget', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editProfileProvider.notifier);
    final originalName = container.read(editProfileProvider).baseline.name;
    final fixedNow = DateTime(2026, 1, 1);
    notifier.setName('New Name');

    notifier.save(now: () => fixedNow);

    final state = container.read(editProfileProvider);
    expect(state.nameChangesUsedThisYear, 1);
    expect(state.nameChangeLog, hasLength(1));
    expect(state.nameChangeLog.single.from, originalName);
    expect(state.nameChangeLog.single.to, 'New Name');
    expect(state.nameChangeLog.single.changedAt, fixedNow);
  });

  test('the 3rd name change within a year is blocked and cannot be saved', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editProfileProvider.notifier);

    notifier.setName('Name One');
    notifier.save();
    notifier.setName('Name Two');
    notifier.save();
    expect(container.read(editProfileProvider).nameChangesRemaining, 0);

    notifier.setName('Name Three');
    final state = container.read(editProfileProvider);
    expect(state.nameChangeBlocked, isTrue);
    expect(state.canSave, isFalse);

    final result = notifier.save();
    expect(result, isFalse);
    // The blocked attempt must not have been committed.
    expect(container.read(editProfileProvider).baseline.name, 'Name Two');
  });

  test('a bio over 150 characters cannot be saved', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editProfileProvider.notifier);

    notifier.setBio('a' * 151);

    expect(container.read(editProfileProvider).canSave, isFalse);
  });

  test('toggling a language twice returns to not-selected', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editProfileProvider.notifier);

    notifier.toggleLanguage('Hindi');
    expect(container.read(editProfileProvider).languages, contains('Hindi'));

    notifier.toggleLanguage('Hindi');
    expect(
      container.read(editProfileProvider).languages,
      isNot(contains('Hindi')),
    );
  });
}
