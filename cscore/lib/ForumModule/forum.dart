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

  Widget _buildNotificationIcon() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      // Query the top-level notification collection for this user
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

    // Build the query dynamically for efficient, server-side filtering
    Query query;
    if (_searchQuery.isNotEmpty) {
      // When searching, filter by title on the server. This is fast and requires no manual index.
      query = FirebaseFirestore.instance
          .collection('forum')
          .where('title', isGreaterThanOrEqualTo: _searchQuery)
          .where('title', isLessThanOrEqualTo: '$_searchQuery\uf8ff')
          .orderBy('title');
    } else {
      // When not searching, just get the most recent forums. This is also fast.
      query = FirebaseFirestore.instance
          .collection('forum')
          .orderBy('timestamp', descending: true);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forums'),
        actions: [
          _buildNotificationIcon(), // Add the notification icon here
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
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(), // Use the new, efficient server-side query
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

                // Filter for visibility on the client-side (this is fast because the list is already small)
                var visibleForums = snapshot.data!.docs.where((doc) {
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
                        trailing: (isPrivate && isCreator)
                            ? ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageForumMembersScreen(forumId: forum.id))), child: const Text('Manage'))
                            : null,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ForumPostsScreen(forumId: forum.id))),
                      ),
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
