import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'post_details_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Please log in to see notifications.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Correctly query the top-level 'notification' collection for the current user
        stream: FirebaseFirestore.instance
            .collection('notification')
            .where('recipientId', isEqualTo: currentUser.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("You have no notifications."));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final data = notification.data() as Map<String, dynamic>;

              final String title = data['title'] ?? 'No Title';
              final String body = data['body'] ?? '';
              final bool isRead = data['isRead'] ?? false;
              final Timestamp? timestamp = data['timestamp'];
              final String date = timestamp != null
                  ? DateFormat('MMM d, yyyy, h:mm a').format(timestamp.toDate())
                  : 'No Date';

              return ListTile(
                tileColor: isRead ? Colors.white : Colors.blue.withOpacity(0.1),
                leading: Icon(
                  data['type'] == 'forum_reply' ? Icons.reply : Icons.delete_forever,
                  color: isRead ? Colors.grey : Colors.blue,
                ),
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('$body\n$date'),
                isThreeLine: true,
                onTap: () async {
                  // Mark as read
                  if (!isRead) {
                    await notification.reference.update({'isRead': true});
                  }

                  // Navigate if it's a reply notification
                  if (data['type'] == 'forum_reply' && data['forumId'] != null && data['postId'] != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostDetailsScreen(
                          forumId: data['forumId'],
                          postId: data['postId'],
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
