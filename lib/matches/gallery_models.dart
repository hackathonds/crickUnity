import 'scoring_models.dart';

/// PRD §7.15: "Match gallery: any squad member uploads ... Clips can be
/// pinned to specific balls." No real media backend exists -- `type`
/// distinguishes photo/video for display purposes only, no actual file
/// is stored.
enum MediaType { photo, video }

class MediaItem {
  final int id;
  final String uploaderName;
  final MediaType type;
  final bool isProcessing;
  final bool isFeatured;
  final bool isHidden;
  final int? pinnedBallIndex;

  const MediaItem({
    required this.id,
    required this.uploaderName,
    required this.type,
    this.isProcessing = false,
    this.isFeatured = false,
    this.isHidden = false,
    this.pinnedBallIndex,
  });

  MediaItem copyWith({
    bool? isProcessing,
    bool? isFeatured,
    bool? isHidden,
    int? pinnedBallIndex,
    bool clearPinnedBallIndex = false,
  }) {
    return MediaItem(
      id: id,
      uploaderName: uploaderName,
      type: type,
      isProcessing: isProcessing ?? this.isProcessing,
      isFeatured: isFeatured ?? this.isFeatured,
      isHidden: isHidden ?? this.isHidden,
      pinnedBallIndex: clearPinnedBallIndex
          ? null
          : (pinnedBallIndex ?? this.pinnedBallIndex),
    );
  }
}

/// PRD §7.15: "auto-compile into a Highlights reel (wickets/boundaries
/// ordered) that the captain can publish." `reelClipIds` is the
/// caption's actual chosen order (not auto-sorted) -- the captain drags
/// to reorder; `reelPublished` gates the final [Publish reel] action.
class GalleryState {
  final List<MediaItem> items;
  final List<int> reelClipIds;
  final bool reelPublished;

  const GalleryState({
    this.items = const [],
    this.reelClipIds = const [],
    this.reelPublished = false,
  });

  List<MediaItem> get visibleItems =>
      items.where((item) => !item.isHidden).toList();

  GalleryState copyWith({
    List<MediaItem>? items,
    List<int>? reelClipIds,
    bool? reelPublished,
  }) {
    return GalleryState(
      items: items ?? this.items,
      reelClipIds: reelClipIds ?? this.reelClipIds,
      reelPublished: reelPublished ?? this.reelPublished,
    );
  }
}

/// DS §7 screen 33: "Highlights builder: clip rail, drag-reorder,
/// [Publish reel] primary; auto-cut chips labeled by moment." Backlog
/// (E4-14): "auto-cut chips when markers/footage exist" -- restricted
/// to clips actually pinned to a wicket/boundary ball, not every
/// key-moment ball in the abstract, since a suggestion needs footage to
/// exist to be "cut."
List<MediaItem> autoCutSuggestions(GalleryState gallery, InningsState innings) {
  return [
    for (final item in gallery.items)
      if (item.pinnedBallIndex != null &&
          !item.isProcessing &&
          !gallery.reelClipIds.contains(item.id) &&
          item.pinnedBallIndex! < innings.deliveries.length &&
          _isKeyMomentBall(innings.deliveries[item.pinnedBallIndex!]))
        item,
  ];
}

bool _isKeyMomentBall(Delivery delivery) =>
    delivery.isWicket || delivery.battingRuns == 4 || delivery.battingRuns == 6;

/// Label for an auto-cut suggestion chip, e.g. "FOUR -- Over 3.2".
String autoCutChipLabel(MediaItem item, InningsState innings) {
  final delivery = innings.deliveries[item.pinnedBallIndex!];
  final moment = delivery.isWicket
      ? 'WICKET'
      : delivery.battingRuns == 6
      ? 'SIX'
      : 'FOUR';
  return '$moment -- ball ${item.pinnedBallIndex! + 1}';
}
