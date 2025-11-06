import 'package:flutter/material.dart';
import '../Services/Firestore_services.dart';
import '../Widgets/Announcement_card.dart';
import '../Widgets/Activity_card.dart';
import '../Screens/create_announcement.dart'; // ✅ Import Create Announcement Page

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final data = LocalDataService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Welcome, Teacher!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.grey[200],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// --- CUSTOM BUTTON CARDS ---
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // ✅ Navigate to Create Announcement Page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateAnnouncementPage(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[300], // Slightly darker card
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "New Announcement",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // TODO: Navigate to Manage Activities Page
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "Manage Activities",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            /// ----------------------------------------

            const Text(
              'Class: Programming',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Manage Activities',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // Activities
            ...data.getActivities().map((a) => ActivityCard(activity: a)),

            const SizedBox(height: 20),
            const Text(
              'Announcements',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            ...data.getAnnouncements()
                .map((a) => AnnouncementCard(announcement: a)),
          ],
        ),
      ),
    );
  }
}