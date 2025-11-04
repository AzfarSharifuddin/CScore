import 'package:cscore/dashboard.dart';
import 'package:cscore/forum.dart';
import 'package:cscore/learning.dart';
import 'package:cscore/quiz.dart';
import 'package:flutter/material.dart';

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
            currentIndex: 4,
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
              else if(index == 3){
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Forum()),);
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