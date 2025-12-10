import 'package:cscore/ForumModule/edit_post_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PostDetailsScreen extends StatefulWidget {
  final String forumId;
  final String postId;

  const PostDetailsScreen({super.key, required this.forumId, required this.postId});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();
  late final Future<String?> _userRoleFuture;
  Map<String, dynamic>? _postData;

  @override
  void initState() {
    super.initState();
    _userRoleFuture = _getUserRole();
  }

  Future<String?> _getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance.collection('user').doc(user.uid).get();
    return doc.data()?['role'];
  }

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  Future<void> _addReply() async {
    if (_replyController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to reply.')),
      );
      return;
    }
    final replierName = (await FirebaseFirestore.instance.collection('user').doc(user.uid).get()).data()?['name'] ?? 'Anonymous';
    final content = _replyController.text.trim(); // Store content before clearing

    _replyController.clear();
    _replyFocusNode.unfocus();

    try {
      await FirebaseFirestore.instance
          .collection('forum').doc(widget.forumId)
          .collection('post').doc(widget.postId)
          .collection('reply').add({
        'content': content,
        'authorName': replierName,
        'authorId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      final postAuthorId = _postData?['authorId'];
      if (postAuthorId != null && postAuthorId != user.uid) {
        await FirebaseFirestore.instance.collection('notification').add({ 
          'recipientId': postAuthorId,
          'title': '$replierName replied to your post',
          'body': _postData?['title'] ?? '',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'forum_reply',
          'forumId': widget.forumId,
          'postId': widget.postId,
        });
      }
    } catch (e) {
        _replyController.text = content;
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context, {String? replyId}) async {
    final isPostDelete = replyId == null;
    final path = isPostDelete
        ? FirebaseFirestore.instance.collection('forum').doc(widget.forumId).collection('post').doc(widget.postId)
        : FirebaseFirestore.instance.collection('forum').doc(widget.forumId).collection('post').doc(widget.postId).collection('reply').doc(replyId);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isPostDelete ? 'Delete Post' : 'Delete Reply'),
        content: const Text('Are you sure? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                 if (isPostDelete) {
                  final postAuthorId = _postData?['authorId'];
                  if (postAuthorId != null && postAuthorId != FirebaseAuth.instance.currentUser!.uid) {
                     await FirebaseFirestore.instance.collection('notification').add({
                        'recipientId': postAuthorId,
                        'title': 'Your post was removed by a moderator',
                        'body': _postData?['title'] ?? '',
                        'timestamp': FieldValue.serverTimestamp(),
                        'isRead': false,
                        'type': 'post_deleted',
                      });
                  }
                }

                await path.delete();
                Navigator.pop(dialogContext);
                if (isPostDelete) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${isPostDelete ? 'Post' : 'Reply'} deleted.')),
                );
              } catch (e) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Post Details')),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([_userRoleFuture, FirebaseFirestore.instance.collection('forum').doc(widget.forumId).collection('post').doc(widget.postId).get()]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final userRole = snapshot.data![0] as String?;
          final postSnapshot = snapshot.data![1] as DocumentSnapshot;

          if (!postSnapshot.exists) {
            return const Center(child: Text("Post not found. It may have been deleted."));
          }

          _postData = postSnapshot.data() as Map<String, dynamic>;
          final isAuthor = currentUser?.uid == _postData!['authorId'];
          final userRoleLower = userRole?.toLowerCase();
          final canModerate = userRoleLower == 'admin' || userRoleLower == 'teacher';

          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_postData!['title'] ?? 'No Title', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('By ${_postData!['authorName'] ?? 'Anonymous'} on ${DateFormat('MMM d, yyyy').format((_postData!['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now())}'),
                            if (isAuthor || canModerate) ...[
                              Row(
                                children: [
                                  if(isAuthor)
                                    TextButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EditPostScreen(
                                              forumId: widget.forumId,
                                              postId: widget.postId,
                                              currentTitle: _postData!['title'] ?? '',
                                              currentContent: _postData!['content'] ?? '',
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.edit, size: 16), label: const Text('Edit Post'),
                                      style: TextButton.styleFrom(foregroundColor: Colors.blueGrey),
                                    ),
                                  TextButton.icon(
                                    onPressed: () => _showDeleteConfirmation(context),
                                    icon: const Icon(Icons.delete, size: 16), label: const Text('Delete Post'),
                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  ),
                                ],
                              )
                            ],
                            const Divider(height: 32),
                            Text(_postData!['content'] ?? 'No Content', style: Theme.of(context).textTheme.bodyLarge),
                            const SizedBox(height: 24),
                            Text('Replies', style: Theme.of(context).textTheme.titleLarge),
                            const Divider(),
                          ],
                        ),
                      ),
                    ),
                    _buildRepliesList(currentUser, canModerate),
                  ],
                ),
              ),
              _buildReplyInputField(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRepliesList(User? currentUser, bool canModerate) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('forum').doc(widget.forumId).collection('post').doc(widget.postId).collection('reply').orderBy('timestamp').snapshots(),
      builder: (context, replySnapshot) {
        if (replySnapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
        }
        if (!replySnapshot.hasData || replySnapshot.data!.docs.isEmpty) {
          return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No replies yet.'))));
        }

        return SliverList(delegate: SliverChildBuilderDelegate((context, index) {
            final reply = replySnapshot.data!.docs[index];
            final replyData = reply.data() as Map<String, dynamic>;
            final isReplyAuthor = currentUser?.uid == replyData['authorId'];

            final timestamp = replyData['timestamp'] as Timestamp?;
            final formattedDate = timestamp != null 
              ? DateFormat('MMM d, yyyy, hh:mm a').format(timestamp.toDate()) 
              : 'Replying...';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          replyData['authorName'] ?? 'Anonymous',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (isReplyAuthor || canModerate)
                          SizedBox(
                            height: 24, // Constrain the button size
                            width: 24,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.delete, size: 18, color: Colors.grey), 
                              onPressed: () => _showDeleteConfirmation(context, replyId: reply.id)
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(formattedDate, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 12),
                    Text(replyData['content'] ?? '', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            );
          }, childCount: replySnapshot.data!.docs.length),
        );
      },
    );
  }

  Widget _buildReplyInputField() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              focusNode: _replyFocusNode,
              decoration: InputDecoration(
                hintText: 'Write a reply...',
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            style: IconButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: _addReply,
          ),
        ],
      ),
    );
  }
}
