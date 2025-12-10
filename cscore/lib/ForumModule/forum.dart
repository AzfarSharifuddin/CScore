import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_forum_screen.dart';
import 'forum_posts_screen.dart';
import 'manage_forum_members_screen.dart';
import 'notification_screen.dart'; // Import the new screen

class Forum extends StatefulWidget {
  const Forum({super.key});

  @override
  State<Forum> createState() => _ForumState();
}

class _ForumState extends State<Forum> {
  late final Future<String?> _userRoleFuture;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _userRoleFuture = _getUserRole();
    _searchController.addListener(() => setState(() => _searchQuery = _searchController.text));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String?> _getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance.collection('user').doc(user.uid).get();
    return doc.data()?['role'];
  }

  Future<void> _deleteForum(String forumId) async {
    // Implement the logic to delete a forum. 
    // This will require deleting the forum document and potentially all sub-collections (posts, replies) manually.
    try {
      final WriteBatch batch = FirebaseFirestore.instance.batch();
      final forumRef = FirebaseFirestore.instance.collection('forum').doc(forumId);

      // Delete all posts and their replies within the forum
      final postsSnapshot = await forumRef.collection('post').get();
      for (final postDoc in postsSnapshot.docs) {
        final repliesSnapshot = await postDoc.reference.collection('reply').get();
        for (final replyDoc in repliesSnapshot.docs) {
          batch.delete(replyDoc.reference); 
        }
        batch.delete(postDoc.reference);
      }

      batch.delete(forumRef); // Delete the forum itself
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Forum deleted successfully.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting forum: $e')));
    }
  }

  void _showDeleteConfirmation(String forumId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Forum'),
        content: const Text('Are you sure you want to delete this entire forum and all its contents? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteForum(forumId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notification')
          .where('recipientId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data?.docs.length ?? 0;

        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
              tooltip: 'Notifications',
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    Query query = FirebaseFirestore.instance
        .collection('forum')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forums'),
        actions: [
          _buildNotificationIcon(),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Forums by Title',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear())
                    : null,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<String?>(
              future: _userRoleFuture,
              builder: (context, userRoleSnapshot) {
                final userRole = userRoleSnapshot.data;
                final canModerate = userRole?.toLowerCase() == 'admin' || userRole?.toLowerCase() == 'teacher';

                return StreamBuilder<QuerySnapshot>(
                  stream: query.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Error: ${snapshot.error}')));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No forums found.'));
                    }

                    var filteredDocs = snapshot.data!.docs;

                    if (_searchQuery.isNotEmpty) {
                      filteredDocs = filteredDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final title = (data['title'] as String?)?.toLowerCase() ?? '';
                        return title.contains(_searchQuery.toLowerCase());
                      }).toList();
                    }

                    var visibleForums = filteredDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final isPrivate = data['access'] == 'private';
                      if (!isPrivate) return true;
                      final members = List<String>.from(data['members'] ?? []);
                      return currentUser != null && members.contains(currentUser.uid);
                    }).toList();

                    if (visibleForums.isEmpty) {
                      return const Center(child: Text('No forums match your search or you do not have access.'));
                    }

                    return ListView.builder(
                      itemCount: visibleForums.length,
                      itemBuilder: (context, index) {
                        final forum = visibleForums[index];
                        final data = forum.data() as Map<String, dynamic>;
                        final isPrivate = data['access'] == 'private';
                        final isCreator = currentUser?.uid == data['creatorId'];

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: ListTile(
                            leading: Icon(isPrivate ? Icons.lock : Icons.public),
                            title: Text(data['title'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(data['description'] ?? 'No Description'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isPrivate && isCreator)
                                  ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageForumMembersScreen(forumId: forum.id))), child: const Text('Manage')),
                                if (canModerate) 
                                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _showDeleteConfirmation(forum.id)),
                              ],
                            ),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ForumPostsScreen(forumId: forum.id))),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FutureBuilder<String?>(
        future: _userRoleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && (snapshot.data == 'Teacher' || snapshot.data == 'Admin')) {
            return FloatingActionButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateForumScreen())),
              child: const Icon(Icons.add),
              tooltip: 'Create Forum',
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
