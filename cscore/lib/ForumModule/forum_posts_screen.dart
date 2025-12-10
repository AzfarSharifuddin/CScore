import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'post_details_screen.dart';
import 'create_forum_post_screen.dart';

class ForumPostsScreen extends StatefulWidget {
  final String forumId;

  const ForumPostsScreen({super.key, required this.forumId});

  @override
  State<ForumPostsScreen> createState() => _ForumPostsScreenState();
}

class _ForumPostsScreenState extends State<ForumPostsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forum Posts'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Posts by Title',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('forum')
                  .doc(widget.forumId)
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

                var posts = snapshot.data!.docs;

                if (_searchQuery.isNotEmpty) {
                  posts = posts.where((post) {
                    final data = post.data() as Map<String, dynamic>;
                    final title = (data['title'] as String?)?.toLowerCase() ?? '';
                    return title.contains(_searchQuery.toLowerCase());
                  }).toList();
                }

                if (posts.isEmpty) {
                  return const Center(child: Text('No posts match your search.'));
                }

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
                              builder: (context) => PostDetailsScreen(forumId: widget.forumId, postId: post.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateForumPostScreen(forumId: widget.forumId),
            ),
          );
        },
        child: const Icon(Icons.add_comment),
        tooltip: 'Add Post',
      ),
    );
  }
}
