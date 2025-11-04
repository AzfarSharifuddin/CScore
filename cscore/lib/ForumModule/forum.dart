//import 'package:cscore/AIModule/ai_chatbox.dart';
import 'package:cscore/DashboardModule/dashboard.dart';

import 'package:cscore/LearningModule/learning.dart';
import 'package:cscore/QuizModule/quiz.dart';
import 'package:cscore/AccountModule/user_profile.dart';
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
      
    );
  }
}