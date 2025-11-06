import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Models/Announcement.dart';
import 'edit_announcement.dart';

class AnnouncementDetailsPage extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementDetailsPage({super.key, required this.announcement});

  Future<void> _deleteAnnouncement(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('Announcements')
        .doc(announcement.id)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Announcement Deleted")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: const Text(
          "Announcement Details",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Title
            Text(
              announcement.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 6),

            /// Date
            Text(
              announcement.date,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),

            const SizedBox(height: 16),
            Divider(color: Colors.grey[300], thickness: 1),
            const SizedBox(height: 16),

            /// Description Text
            Text(
              announcement.description,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),

            const Spacer(),

            /// Only show edit + delete if user is the creator
            if (user != null && user.uid == announcement.createdBy) ...[
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: const Color(0xFFDDEAF7), // soft blue
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditAnnouncementPage(announcement: announcement),
                        ),
                      );
                    },
                    child: const Text(
                      "Edit Announcement",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: Colors.redAccent,
                  ),
                  child: TextButton(
                    onPressed: () => _deleteAnnouncement(context),
                    child: const Text(
                      "Delete Announcement",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
