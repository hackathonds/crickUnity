import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'gallery_models.dart';

/// PRD §7.15 -- E4-14's Gallery/highlights state. No real media/storage
/// backend exists yet, so "upload" appends a placeholder [MediaItem]
/// rather than handling any actual file.
class GalleryNotifier extends PersistedNotifier<GalleryState> {
  @override
  String get persistenceKey => 'gallery_v1';

  @override
  GalleryState seed() => const GalleryState();

  @override
  Map<String, dynamic> toJson(GalleryState value) => value.toJson();

  @override
  GalleryState fromJson(Map<String, dynamic> json) =>
      GalleryState.fromJson(json);

  /// Computed from current state rather than a separate incrementing
  /// field -- a plain field would restart at 0 after every app restart
  /// and collide with ids already restored from disk.
  int get _nextId => state.items.isEmpty
      ? 0
      : state.items.map((i) => i.id).reduce((a, b) => a > b ? a : b) + 1;

  /// PRD screen-list #38: "processing state." Mirrors the offline
  /// queue's simulated-delay convention (E4-08) -- always succeeds
  /// after a short delay, no real upload pipeline exists.
  Future<void> uploadItem({
    required String uploaderName,
    required MediaType type,
  }) async {
    final id = _nextId;
    state = state.copyWith(
      items: [
        ...state.items,
        MediaItem(
          id: id,
          uploaderName: uploaderName,
          type: type,
          isProcessing: true,
        ),
      ],
    );
    await Future.delayed(const Duration(milliseconds: 600));
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == id) item.copyWith(isProcessing: false) else item,
      ],
    );
  }

  void toggleFeatured(int itemId) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == itemId)
            item.copyWith(isFeatured: !item.isFeatured)
          else
            item,
      ],
    );
  }

  void toggleHidden(int itemId) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == itemId)
            item.copyWith(isHidden: !item.isHidden)
          else
            item,
      ],
    );
  }

  /// PRD §7.15: "Clips can be pinned to specific balls ('attach to:
  /// 14.3') -> appear in ball timeline."
  void pinToBall(int itemId, int deliveryIndex) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == itemId)
            item.copyWith(pinnedBallIndex: deliveryIndex)
          else
            item,
      ],
    );
  }

  void unpinFromBall(int itemId) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == itemId)
            item.copyWith(clearPinnedBallIndex: true)
          else
            item,
      ],
    );
  }

  void addToReel(int itemId) {
    if (state.reelClipIds.contains(itemId)) return;
    state = state.copyWith(reelClipIds: [...state.reelClipIds, itemId]);
  }

  void removeFromReel(int itemId) {
    state = state.copyWith(
      reelClipIds: [
        for (final id in state.reelClipIds)
          if (id != itemId) id,
      ],
    );
  }

  void reorderReel(int oldIndex, int newIndex) {
    final clips = [...state.reelClipIds];
    final id = clips.removeAt(oldIndex);
    clips.insert(newIndex, id);
    state = state.copyWith(reelClipIds: clips);
  }

  /// PRD §7.15: "a Highlights reel ... that the captain can publish."
  /// Captain-only gate is enforced structurally by the screen (the
  /// button is never built for non-captains) -- this just records it.
  void publishReel() {
    state = state.copyWith(reelPublished: true);
  }
}

final galleryProvider = NotifierProvider<GalleryNotifier, GalleryState>(
  GalleryNotifier.new,
);
