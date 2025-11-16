import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cscore/ProgressTrackerModule/Screens/view_progress.dart';
import 'package:cscore/DashboardModule/Screens/student_profile.dart';

// --- Mock classes for Activities & Materials only ---
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
}

class Activity {
  final String title;
  final String dueDate;
  final String description;
  Activity({
    required this.title,
    required this.dueDate,
    required this.description,
  });
}

class MaterialItem {
  final String title;
  final String type;
  MaterialItem({required this.title, required this.type});
}

class Announcement {
  final String title;
  final String description;
  final String date;

  Announcement({
    required this.title,
    required this.description,
    required this.date,
  });
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
          color: material.type == 'PDF' ? Colors.red[600] : Colors.green[600],
        ),
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
        title: Text(
          announcement.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(announcement.description),
        trailing: Text(
          announcement.date,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }
}

// ----------------------------
//        STUDENT DASHBOARD
// ----------------------------

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
            const SizedBox(height: 16),

            // --- Buttons ---
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
                const SizedBox(width: 12),
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
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
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

            const SizedBox(height: 24),
            const Text('Upcoming Activities',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            ...data.getActivities().map((a) => ActivityCard(activity: a)),

            const SizedBox(height: 16),
            const Text('Class Materials',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            ...data.getMaterials().map((m) => MaterialCard(material: m)),

            const SizedBox(height: 16),
            const Text('Announcements',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            // 🔥 REAL-TIME ANNOUNCEMENT STREAM
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('announcement')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Text("No announcements available.");
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return AnnouncementCard(
                      announcement: Announcement(
                        title: data['Title'] ?? '',
                        description: data['Description'] ?? '',
                        date: data['Date'] ?? '',
                      ),
                    );
                  }).toList(),
                );
              },
            ),
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
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => ViewProgressScreen()));
          } else if (index == 2) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const StudentProfile()));
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
