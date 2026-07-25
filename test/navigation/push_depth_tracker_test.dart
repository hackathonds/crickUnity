import 'package:cricunity/navigation/push_depth_tracker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a push beyond maxPushDepth from a tab root is blocked', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(pushDepthProvider.notifier);

    for (var i = 0; i < maxPushDepth; i++) {
      expect(notifier.push(0), isTrue);
    }
    expect(notifier.depthOf(0), maxPushDepth);
    expect(notifier.canPush(0), isFalse);
    expect(notifier.push(0), isFalse);
    expect(notifier.depthOf(0), maxPushDepth);
  });

  test('pop decrements depth and never goes below zero', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(pushDepthProvider.notifier);

    notifier.push(0);
    notifier.push(0);
    notifier.pop(0);
    expect(notifier.depthOf(0), 1);

    notifier.pop(0);
    notifier.pop(0);
    expect(notifier.depthOf(0), 0);
  });

  test('depth is tracked independently per branch', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(pushDepthProvider.notifier);

    notifier.push(0);
    notifier.push(0);
    notifier.push(1);

    expect(notifier.depthOf(0), 2);
    expect(notifier.depthOf(1), 1);
    expect(notifier.depthOf(2), 0);
  });

  test('reset zeroes a branch without touching others', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(pushDepthProvider.notifier);

    notifier.push(0);
    notifier.push(1);
    notifier.reset(0);

    expect(notifier.depthOf(0), 0);
    expect(notifier.depthOf(1), 1);
  });
}
