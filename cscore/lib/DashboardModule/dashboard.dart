//import 'package:cscore/AIModule/ai_chatbox.dart';
//import 'package:cscore/ForumModule/forum.dart';
//import 'package:cscore/LearningModule/learning.dart';
import 'package:cscore/ProgressTrackerModule/progress.dart';
//import 'package:cscore/QuizModule/quiz.dart';
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
      
      body: Padding(padding: EdgeInsetsGeometry.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: Text('Welcome to CScore+',style: TextStyle(fontSize: 20),),
            ),
            Divider(
              height: 60,
              color: Colors.grey[800],
            ),
            
            Text(
              'Learning Modules',
              style: TextStyle(
                color: Colors.blue,
                letterSpacing: 2.0,
              
              ),
            ),
            SizedBox(height:10),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(color: Colors.green[200],child: Text('HTML'),width: 100, height: 100,),
                SizedBox(width:10),
                Container(color: Colors.amber[200],child: Text('CSS'),width: 100, height: 100,),
              ],
            ),


            TextButton(
              onPressed: (){
                Navigator.pushNamed(context, '/learning');
              }, 
              child: Text('Go to Learning Module'),
              ),
             Divider(
              height: 60,
              color: Colors.grey[800],
            ),
            
            Text(
              'Quizzes and Assessment',
              style: TextStyle(
                color: Colors.blue,
                letterSpacing: 2.0,
              
              ),
            ),
            SizedBox(height:10),
            Row(
              children: [
                Container(color: Colors.green[200],child: Text('HTML'),width: 100, height: 100,),
                SizedBox(width:10),
                Container(color: Colors.amber[200],child: Text('CSS'),width: 100, height: 100,),
              ],
            ),
            TextButton(
              onPressed: (){
                Navigator.pushNamed(context, '/quiz');
              }, 
              child: Text('Go to Quizzes and Assessment'),
              ),
              
            
        ],
      ),),
      
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
            currentIndex: 1,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.black,
            onTap: (index){
              if(index == 0){
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProgressTracker()),);
              }
              else if(index == 2){
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const UserProfile()),);
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