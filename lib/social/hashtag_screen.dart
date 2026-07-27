import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'feed_models.dart';
import 'feed_provider.dart';
import 'post_detail_screen.dart';

/// PRD §12.6: "Hashtags -> tag pages with Top/Recent." Top = ranked by
/// the same rankedScore() E7-01's "For You" sort already uses; Recent =
/// pure chronological. Reuses that scoring rather than inventing a
/// second ranking formula for one tab.
class HashtagScreen extends ConsumerStatefulWidget {
  final String hashtag;

  const HashtagScreen({super.key, required this.hashtag});

  @override
  ConsumerState<HashtagScreen> createState() => _HashtagScreenState();
}

class _HashtagScreenState extends ConsumerState<HashtagScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(feedProvider).posts;
    final tag = '#${widget.hashtag}';
    final matching = posts
        .where(
          (p) =>
              p.deletedAt == null &&
              p.contentText.toLowerCase().contains(tag.toLowerCase()),
        )
        .toList();
    final now = DateTime.now();

    final top = [...matching]
      ..sort((a, b) => rankedScore(b, now).compareTo(rankedScore(a, now)));
    final recent = [...matching]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      appBar: AppBar(
        title: Text(tag),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Top'),
            Tab(text: 'Recent'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _HashtagPostList(posts: top),
          _HashtagPostList(posts: recent),
        ],
      ),
    );
  }
}

class _HashtagPostList extends StatelessWidget {
  final List<FeedPost> posts;

  const _HashtagPostList({required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Center(child: Text('No posts with this hashtag yet.'));
    }
    return ListView(
      children: [
        for (final post in posts)
          ListTile(
            key: ValueKey('hashtagPostRow_${post.id}'),
            title: Text(post.authorName),
            subtitle: Text(
              post.contentText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PostDetailScreen(postId: post.id),
              ),
            ),
          ),
      ],
    );
  }
}
