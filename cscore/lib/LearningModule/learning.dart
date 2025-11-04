//import 'package:cscore/AIModule/ai_chatbox.dart';
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
      
    );
  }
}