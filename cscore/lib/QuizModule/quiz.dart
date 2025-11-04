
import 'package:cscore/DashboardModule/dashboard.dart';
import 'package:cscore/ForumModule/forum.dart';
import 'package:cscore/LearningModule/learning.dart';
import 'package:cscore/AccountModule/user_profile.dart';
import 'package:flutter/material.dart';

class Quiz extends StatefulWidget {
  const Quiz({super.key});

  @override
  State<Quiz> createState() => _QuizState();
}

class _QuizState extends State<Quiz> {
  final List<String> topics = ['HTML','CSS','JAVASCRIPT'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz'),
        backgroundColor: Colors.grey[200],
      
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: topics.length,
          itemBuilder: (context, index) {
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topics[index],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Navigate to quiz attempt page for this topic
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Attempting ${topics[index]} quiz...'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text('Attempt'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),


      
      bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: 2,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.black,
            onTap: (index){
              if(index == 0){
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Dashboard()),);
              }
              else if(index == 1){
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Learning()),);
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

