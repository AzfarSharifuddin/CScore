import 'package:cscore/DashboardModule/dashboard.dart';
import 'package:cscore/ForumModule/forum.dart';
import 'package:cscore/LearningModule/learning.dart';
import 'package:cscore/QuizModule/Student/quiz.dart';
import 'package:cscore/ProgressTrackerModule/Screens/view_progress.dart';
import 'package:flutter/material.dart';
//tambah 1
//tambah 2
//tambah 3


class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
        backgroundColor: Colors.grey[200],
      ),
      body: Text('User'),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 2, // Stays at 1 for the 'Home' screen
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black,
        onTap: (index) {
          if (index == 0) {
            // FIXED: Use 'push' to allow user to go back
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ViewProgressScreen()),
            );
          } /*else if (index == 1) {
             // FIXED: Enabled this navigation and used 'push'
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserProfile()),
            );
          } will fix later 7/11/25*/
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Progress', // FIXED: Added label
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home', // FIXED: Added label
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile', // FIXED: Added label
          ),
        ],
      ),
    );
  }
}