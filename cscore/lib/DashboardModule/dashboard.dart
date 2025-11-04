// dashboard.dart

//import 'package:cscore/AIModule/ai_chatbox.dart';
//import 'package:cscore/ForumModule/forum.dart';
//import 'package:cscore/LearningModule/learning.dart';
import 'package:cscore/ProgressTrackerModule/progress.dart';
//import 'package:cscore/QuizModule/quiz.dart';
import 'package:cscore/AccountModule/user_profile.dart';
import 'package:flutter/material.dart';

// import your teacher/student dashboard screens
import 'package:cscore/DashboardModule/Screens/teacher_dashboard.dart';
import 'package:cscore/DashboardModule/Screens/student_dashboard.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CScore+'),
        backgroundColor: Colors.grey[200],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
            Center(
              child: Text(
                'Welcome to CScore+',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Divider(height: 40, color: Colors.grey[800]),

            // Learning Module Section
            const Text(
              'Learning Modules',
              style: TextStyle(
                color: Colors.blue,
                letterSpacing: 1.5,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  color: Colors.green[200],
                  width: 100,
                  height: 100,
                  alignment: Alignment.center,
                  child: const Text('HTML'),
                ),
                const SizedBox(width: 10),
                Container(
                  color: Colors.amber[200],
                  width: 100,
                  height: 100,
                  alignment: Alignment.center,
                  child: const Text('CSS'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/learning');
              },
              child: const Text('Go to Learning Module'),
            ),
            Divider(height: 40, color: Colors.grey[800]),

            // Quizzes Section
            const Text(
              'Quizzes and Assessment',
              style: TextStyle(
                color: Colors.blue,
                letterSpacing: 1.5,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  color: Colors.green[200],
                  width: 100,
                  height: 100,
                  alignment: Alignment.center,
                  child: const Text('HTML'),
                ),
                const SizedBox(width: 10),
                Container(
                  color: Colors.amber[200],
                  width: 100,
                  height: 100,
                  alignment: Alignment.center,
                  child: const Text('CSS'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/quiz');
              },
              child: const Text('Go to Quizzes and Assessment'),
            ),
            Divider(height: 40, color: Colors.grey[800]),

            // 🔹 NEW: Teacher/Student Dashboard Selector
            const Text(
              'Dashboard Access',
              style: TextStyle(
                color: Colors.blue,
                letterSpacing: 1.5,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select your role to access the dashboard:',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TeacherDashboard(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.school),
                    label: const Text('Teacher Dashboard'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[700],
                      foregroundColor: Colors.white,
                      minimumSize: const Size(230, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StudentDashboard(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person),
                    label: const Text('Student Dashboard'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(230, 55),
                      side: const BorderSide(color: Colors.blueGrey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Divider(),
            const Center(
              child: Text(
                'You can track your learning and progress using the bottom navigation bar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.grey[200],
        shape: const CircleBorder(),
        child: Text(
          'AI CHAT',
          style: TextStyle(color: Colors.grey[800]),
        ),
        onPressed: () {
          Navigator.pushNamed(context, '/ai');
        },
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
              MaterialPageRoute(builder: (context) => const ProgressTracker()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const UserProfile()),
            );
          }
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