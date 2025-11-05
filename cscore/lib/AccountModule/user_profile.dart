import 'package:cscore/DashboardModule/dashboard.dart';
import 'package:cscore/ForumModule/forum.dart';
import 'package:cscore/LearningModule/learning.dart';
import 'package:cscore/QuizModule/quiz.dart';
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
            currentIndex: 2,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.black,
            onTap: (index){
              if(index == 0){
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ViewProgressScreen()),);
              }
              else if(index == 1){
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Dashboard()),);
              }

            },
            items: const[
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