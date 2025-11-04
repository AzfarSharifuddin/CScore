import 'package:flutter/material.dart';
import '../Services/Firestore_services.dart';
import '../Widgets/Announcement_card.dart';
import '../Widgets/Activity_card.dart';
import '../Widgets/Materials_card.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final data = LocalDataService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome, Student!'),
        backgroundColor: Colors.grey[200],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Class: Programming',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Upcoming Activities',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            ...data.getActivities().map((a) => ActivityCard(activity: a)),

            const SizedBox(height: 16),
            const Text('Class Materials',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ...data.getMaterials().map((m) => MaterialCard(material: m)),

            const SizedBox(height: 16),
            const Text('Announcements',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ...data.getAnnouncements()
                .map((a) => AnnouncementCard(announcement: a)),
          ],
        ),
      ),
    );
  }
}
