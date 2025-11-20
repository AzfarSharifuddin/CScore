import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cscore/ProgressTrackerModule/Screens/view_progress.dart';
import 'package:cscore/DashboardModule/Screens/student_profile.dart';
import 'activity_details.dart';

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

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'Class: Programming',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 🔹 FIXED BUTTON ALIGNMENT
            Row(
              children: [
                Expanded(
                  child: CustomDashboardButton(
                    icon: Icons.school_rounded,
                    label: 'Modules',
                    onPressed: () {
                      Navigator.pushNamed(context, '/learning');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomDashboardButton(
                    icon: Icons.quiz_rounded,
                    label: 'Quizzes',
                    onPressed: () {
                      Navigator.pushNamed(context, '/quiz');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomDashboardButton(
                    icon: Icons.forum_rounded,
                    label: 'Forum',
                    onPressed: () {
                      Navigator.pushNamed(context, '/forum');
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text('Upcoming Activities',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('activity')
                  .orderBy('deadline')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Text("No upcoming activities.");
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(data['title'] ?? 'No Title'),
                        subtitle: Text(data['description'] ?? ''),
                        trailing: Text(
                          (data['deadline'] as Timestamp)
                              .toDate()
                              .toString()
                              .substring(0, 10),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ActivityDetailsPage(
                                activityId: doc.id,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),
            const Text('Announcements',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

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
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(data['Title'] ?? ''),
                        subtitle: Text(data['Description'] ?? ''),
                        trailing: Text(
                          data['Date'] ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
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
        currentIndex: 1,
        selectedItemColor: Colors.blue,
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ViewProgressScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StudentProfilePage()),
            );
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

// 🔹 REUSABLE BUTTON FIX
class CustomDashboardButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const CustomDashboardButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15),
              softWrap: false,
              overflow: TextOverflow.fade,
            ),
          ),
        ],
      ),
    );
  }
}
