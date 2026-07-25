import 'package:cricunity/offline/is_online_provider.dart';
import 'package:cricunity/offline/queued_action.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'a non-money action submitted while offline queues as pending',
    () async {
      final container = ProviderContainer(
        overrides: [isOnlineProvider.overrideWith((ref) => false)],
      );
      addTearDown(container.dispose);

      await container
          .read(queuedActionsProvider.notifier)
          .submit(
            label: 'Availability: Yes',
            isMoneyAction: false,
            perform: () async {},
          );

      final state = container.read(queuedActionsProvider);
      expect(state, hasLength(1));
      expect(state.single.status, QueuedActionStatus.pending);
    },
  );

  test(
    'a money action submitted while offline is rejected immediately as an error, never queued',
    () async {
      final container = ProviderContainer(
        overrides: [isOnlineProvider.overrideWith((ref) => false)],
      );
      addTearDown(container.dispose);

      await container
          .read(queuedActionsProvider.notifier)
          .submit(
            label: 'Pay ground fee',
            isMoneyAction: true,
            perform: () async {},
          );

      final state = container.read(queuedActionsProvider);
      expect(state, hasLength(1));
      expect(state.single.status, QueuedActionStatus.error);
    },
  );

  test(
    'reconnecting resolves every pending action to success or error per its outcome',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(isOnlineProvider.notifier).state = false;

      final notifier = container.read(queuedActionsProvider.notifier);
      await notifier.submit(
        label: 'will succeed',
        isMoneyAction: false,
        perform: () async {},
      );
      await notifier.submit(
        label: 'will fail',
        isMoneyAction: false,
        perform: () async {
          throw Exception('boom');
        },
      );

      expect(
        container
            .read(queuedActionsProvider)
            .every((a) => a.status == QueuedActionStatus.pending),
        isTrue,
      );

      container.read(isOnlineProvider.notifier).state = true;
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final resolved = container.read(queuedActionsProvider);
      final succeeded = resolved.firstWhere((a) => a.label == 'will succeed');
      final failed = resolved.firstWhere((a) => a.label == 'will fail');
      expect(succeeded.status, QueuedActionStatus.success);
      expect(failed.status, QueuedActionStatus.error);
    },
  );

  test(
    'online submissions resolve immediately without ever going pending-and-stuck',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(queuedActionsProvider.notifier)
          .submit(label: 'ok', isMoneyAction: true, perform: () async {});

      final state = container.read(queuedActionsProvider);
      expect(state.single.status, QueuedActionStatus.success);
    },
  );
}
