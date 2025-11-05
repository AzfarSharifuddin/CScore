import 'package:flutter/material.dart';
import 'package:cscore/ProgressTrackerModule/Screens/view_progress.dart';
//import 'package:cscore/AccountModule/user_profile.dart';
// Assuming these imports are correct for your project structure
// import '../Services/Firestore_services.dart';
// import '../Widgets/Announcement_card.dart';
// import '../Widgets/Activity_card.dart';
// import '../Widgets/Materials_card.dart';

// --- Mock Classes (so the file is self-contained) ---
// You can remove these if you have the real files imported.
class LocalDataService {
  List<Activity> getActivities() => [
        Activity(
            title: 'Programming Assignment',
            dueDate: 'Thu, Sep 5',
            description: 'Submit via portal before midnight.'),
        Activity(
            title: 'Web Dev Practice',
            dueDate: 'Thu, Sep 5',
            description: 'Review Python loops and HTML forms.'),
      ];
  List<MaterialItem> getMaterials() => [
        MaterialItem(title: 'CSS Layout Notes.pdf', type: 'PDF'),
        MaterialItem(title: 'Python Loops Video', type: 'Video'),
      ];
  List<Announcement> getAnnouncements() => [
        Announcement(
            title: 'Database Assignment Due',
            date: 'Tuesday, September 3',
            description: 'Submit Database assignment by 5 PM today.'),
        Announcement(
            title: 'Web Development Test',
            date: 'September 9, 2024',
            description: 'Test on Chapter 3 next Monday.'),
      ];
}

class Activity {
  final String title;
  final String dueDate;
  final String description;
  Activity(
      {required this.title, required this.dueDate, required this.description});
}

class MaterialItem {
  final String title;
  final String type;
  MaterialItem({required this.title, required this.type});
}

class Announcement {
  final String title;
  final String date;
  final String description;
  Announcement(
      {required this.title, required this.date, required this.description});
}

class ActivityCard extends StatelessWidget {
  final Activity activity;
  const ActivityCard({super.key, required this.activity});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.calendar_today_rounded, color: Colors.blue[600]),
        title: Text(activity.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${activity.dueDate}\n${activity.description}'),
        isThreeLine: true,
      ),
    );
  }
}

class MaterialCard extends StatelessWidget {
  final MaterialItem material;
  const MaterialCard({super.key, required this.material});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
            material.type == 'PDF'
                ? Icons.picture_as_pdf_rounded
                : Icons.video_library_rounded,
            color: material.type == 'PDF' ? Colors.red[600] : Colors.green[600]),
        title: Text(material.title),
      ),
    );
  }
}

class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  const AnnouncementCard({super.key, required this.announcement});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(announcement.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(announcement.description),
        trailing: Text(announcement.date,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ),
    );
  }
}
// --- End of Mock Classes ---

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
            const SizedBox(height: 16), // Increased spacing

            // --- Buttons for Modules, Quizzes, and Forum ---
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/learning');
                    },
                    icon: const Icon(Icons.school_rounded),
                    label: const Text('Modules'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12), // Adjusted spacing
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/quiz');
                    },
                    icon: const Icon(Icons.quiz_rounded),
                    label: const Text('Quizzes'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12), // <-- NEW SPACING
                Expanded( // <-- NEW BUTTON
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to Forum page
                      Navigator.pushNamed(context, '/forum');
                    },
                    icon: const Icon(Icons.forum_rounded),
                    label: const Text('Forum'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // --- End of Buttons ---

            const SizedBox(height: 24), // Increased spacing
            const Text('Upcoming Activities',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            ...data.getActivities().map((a) => ActivityCard(activity: a)),

            const SizedBox(height: 16),
            const Text('Class Materials',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8), // Added spacing here
            ...data.getMaterials().map((m) => MaterialCard(material: m)),

            const SizedBox(height: 16),
            const Text('Announcements',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8), // Added spacing here
            ...data
                .getAnnouncements()
                .map((a) => AnnouncementCard(announcement: a)),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 1,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ViewProgressScreen()),
            );
          } /*else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const UserProfile()),
            );
          }*/
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '',
          ),
        ],
      ),
    );
  }
}
