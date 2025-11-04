import 'package:cscore/dashboard.dart';
import 'package:cscore/user_profile.dart';
import 'package:cscore/learning.dart';
import 'package:cscore/quiz.dart';
import 'package:flutter/material.dart';

class Forum extends StatefulWidget {
  const Forum({super.key});

  @override
  State<Forum> createState() => _ForumState();
}

class _ForumState extends State<Forum> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forum'),
        backgroundColor: Colors.grey[200],
      ),
      body: Text('Forum page'),
      bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: 3,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.black,
            onTap: (index){
              if(index == 0){
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Dashboard()),);
              }
              else if(index == 1){
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Learning()),);
              }
              else if(index == 2){
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Quiz()),);
              }
              else if(index == 4){
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const UserProfile()),);
              }
            },
            items: const[
              BottomNavigationBarItem(
                    
                    icon: Icon(Icons.home),
                    label: '', 
                    
                ),
                BottomNavigationBarItem(
                    
                    icon: Icon(Icons.school),
                    label: '', 
                    
                ),
                BottomNavigationBarItem(
      
                    icon: Icon(Icons.lightbulb_circle_outlined),
                    label: '', 
                ),
                BottomNavigationBarItem(
                    
                    icon: Icon(Icons.forum),
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