import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'post_details_screen.dart'; 
import 'create_forum_post_screen.dart';

class ForumPostsScreen extends StatelessWidget {
  final String forumId;

  const ForumPostsScreen({super.key, required this.forumId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forum Posts'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Use singular names: 'forum' and 'post'
        stream: FirebaseFirestore.instance
            .collection('forum')
            .doc(forumId)
            .collection('post')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No posts in this forum yet. Be the first!'));
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final data = post.data() as Map<String, dynamic>;

              final String title = data['title'] ?? 'No Title';
              final String author = data['authorName'] ?? 'Anonymous';
              final Timestamp? timestamp = data['timestamp'];

              final String date = timestamp != null
                  ? DateFormat('MMM d, yyyy').format(timestamp.toDate())
                  : 'No Date';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('By $author on $date'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailsScreen(forumId: forumId, postId: post.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateForumPostScreen(forumId: forumId),
            ),
          );
        },
        child: const Icon(Icons.add_comment),
        tooltip: 'Add Post',
      ),
    );
  }
}
