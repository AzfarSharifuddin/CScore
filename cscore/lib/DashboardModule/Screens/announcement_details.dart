import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Models/Announcement.dart';
import 'edit_announcement.dart'; // ✅ Add this

class AnnouncementDetailsPage extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementDetailsPage({super.key, required this.announcement});

  Future<void> _deleteAnnouncement(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('Announcements')
        .doc(announcement.id)
        .delete();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("✅ Announcement Deleted")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Announcement Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              announcement.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(announcement.date, style: const TextStyle(color: Colors.grey)),
            const Divider(height: 32),
            Text(
              announcement.description,
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),

            // ✅ Only creator sees Edit/Delete
            if (user != null && user.uid == announcement.createdBy) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditAnnouncementPage(announcement: announcement),
                      ),
                    );
                  },
                  child: const Text("Edit Announcement"),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _deleteAnnouncement(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Delete Announcement"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
