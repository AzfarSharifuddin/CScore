//import 'package:cscore/AIModule/ai_chatbox.dart';
import 'package:cscore/ForumModule/forum.dart';
import 'package:cscore/LearningModule/learning.dart';
import 'package:cscore/QuizModule/quiz.dart';
import 'package:cscore/AccountModule/user_profile.dart';
import 'package:flutter/material.dart';
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
        title: Text('CScore+'),
        backgroundColor: Colors.grey[200],
        
      ),
      
      body: Text('Dashboard page'),
      
      floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.grey[200],
            shape: const CircleBorder(),
            child: Text('AI CHAT', style: TextStyle(color: Colors.grey[800]),),
            onPressed: () {
              Navigator.pushNamed(context, '/ai');
            },
        ),
      
      
      bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: 0,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.black,
            onTap: (index){
              if(index == 1){
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Learning()),);
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