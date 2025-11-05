import 'package:cscore/AIModule/ai_chatbox.dart';
import 'package:cscore/DashboardModule/dashboard.dart';
import 'package:cscore/ForumModule/forum.dart';
import 'package:cscore/LearningModule/ViewTutorial/viewtutorial.dart';
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
<<<<<<< Updated upstream
      '/learning': (context) => ViewTutorialPage(),
      '/quiz': (context) => Quiz(),
=======
      '/learning': (context) => Learning(),
      '/quiz': (context) => QuizListPage(),
>>>>>>> Stashed changes
      '/ai': (context) => AiChatBot(),
      '/forum': (context) => Forum(),
    },
  ));
}




