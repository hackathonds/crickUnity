import 'package:flutter/material.dart';

import '../components/app_comment_widget.dart';
import '../tokens/app_spacing.dart';

/// QA tool for E0-08 (sub-task 7/12): [AppCommentComposer],
/// [AppCommentThread] (with expandable replies).
class CommentWidgetScreen extends StatefulWidget {
  const CommentWidgetScreen({super.key});

  @override
  State<CommentWidgetScreen> createState() => _CommentWidgetScreenState();
}

class _CommentWidgetScreenState extends State<CommentWidgetScreen> {
  late List<AppCommentData> _comments;

  @override
  void initState() {
    super.initState();
    _comments = [
      const AppCommentData(
        authorName: 'Rahul Verma',
        timeAgo: '2h',
        body: 'Great win today, that final over was intense!',
        propsCount: 4,
        replies: [
          AppCommentData(
            authorName: 'Priya Nair',
            timeAgo: '1h',
            body: 'Absolutely, Deepak bowled brilliantly.',
          ),
          AppCommentData(
            authorName: 'Arjun Rao',
            timeAgo: '45m',
            body: 'That catch in the deep sealed it.',
          ),
        ],
      ),
      const AppCommentData(
        authorName: 'Simran Kaur',
        timeAgo: '30m',
        body: 'When is the next match scheduled?',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comment widget (QA)')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppCommentThread(
                comments: _comments,
                onPropsTap: (c) => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Propped ${c.authorName}')),
                ),
                onReplyTap: (c) => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Reply to ${c.authorName}')),
                ),
              ),
            ),
          ),
          AppCommentComposer(
            authorName: 'Deepak Sharma',
            onSubmit: (text) => setState(() {
              _comments = [
                ..._comments,
                AppCommentData(
                  authorName: 'Deepak Sharma',
                  timeAgo: 'now',
                  body: text,
                ),
              ];
            }),
          ),
        ],
      ),
    );
  }
}
