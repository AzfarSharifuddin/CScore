import 'package:cscore/AIModule/ai_chatbox.dart';
import 'package:cscore/DashboardModule/dashboard.dart';
import 'package:cscore/ForumModule/forum.dart';
import 'package:cscore/QuizModule/quiz.dart';
import 'package:cscore/AccountModule/user_profile.dart';
import 'package:flutter/material.dart';

class Learning extends StatefulWidget {
  const Learning({super.key});

  @override
  State<Learning> createState() => _LearningState();
}

class _LearningState extends State<Learning> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Learning'),
        backgroundColor: Colors.grey[200],
      
      ),
      body: Text('Learning page'),
      bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: 1,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.black,
            onTap: (index){
              if(index == 0){
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Dashboard()),);
              }
              else if(index == 2){
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Quiz()),);
              }
              else if(index == 3){
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Forum()),);
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