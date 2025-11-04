import 'package:cscore/AIModule/ai_chatbox.dart';
import 'package:cscore/DashboardModule/dashboard.dart';
import 'package:cscore/ForumModule/forum.dart';
import 'package:cscore/LearningModule/learning.dart';
import 'package:cscore/QuizModule/quiz.dart';
import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(
  initialRoute: '/',
  routes: {
    '/':(context) => Dashboard(),
    '/learning':(context) => Learning(),
    '/quiz':(context) => Quiz(),
    '/ai':(context) => AiChatBot(), 
    '/forum':(context) => Forum(),


  },
));



