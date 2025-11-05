import 'package:flutter/material.dart';
import '../Services/Firestore_services.dart';
import '../Widgets/Announcement_card.dart';
import '../Widgets/Materials_card.dart';
import '../Widgets/Activity_card.dart';

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

            /// --- UPDATED BUTTONS (NOW LOOK LIKE CARDS) ---
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // TODO: Navigate to Create Announcement Page
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],  // Slightly darker
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "New Announcement",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold, // Same as "Class: Programming"
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
                        color: Colors.grey[300], // Same box color
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "Manage Activities",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold, // Same font style
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            /// -------------------------------------------------

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

            const SizedBox(height: 20),
            const Text(
              'Class Materials',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            ...data.getMaterials().map((m) => MaterialCard(material: m)),
          ],
        ),
      ),
    );
  }
}
