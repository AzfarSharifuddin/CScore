import 'package:cscore/AIModule/ai_chatbox.dart';
import 'package:cscore/DashboardModule/dashboard.dart';
import 'package:cscore/ForumModule/forum.dart';
import 'package:cscore/LearningModule/learning.dart';
import 'package:cscore/QuizModule/quiz.dart';
import 'package:cscore/AccountModule/screen/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cscore/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); 

  await Firebase.initializeApp(
    options:DefaultFirebaseOptions.currentPlatform
  );

  runApp(MaterialApp(
    initialRoute: '/',
    routes: {
      '/': (context) => LoginPage(),
      '/learning': (context) => Learning(),
      '/quiz': (context) => Quiz(),
      '/ai': (context) => AiChatBot(),
      '/forum': (context) => Forum(),
    },
  ));
}




