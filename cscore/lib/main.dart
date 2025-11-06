import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cscore/firebase_options.dart';
import 'package:cscore/AIModule/ai_chatbox.dart';
import 'package:cscore/DashboardModule/dashboard.dart';
import 'package:cscore/ForumModule/forum.dart';
import 'package:cscore/LearningModule/ViewTutorial/viewtutorial.dart';
import 'package:cscore/QuizModule/Student/quiz.dart';
import 'package:cscore/AccountModule/screen/login.dart';
import 'package:cscore/AccountModule/screen/registration.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const CScoreApp());
}

class CScoreApp extends StatelessWidget {
  const CScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CScore+',

   
      initialRoute: '/',

  
      routes: {
        '/': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(), 
        '/dashboard': (context) => const Dashboard(),
        '/learning': (context) => const ViewTutorialPage(),
        '/quiz': (context) => const QuizListPage(),
        '/ai': (context) => const AiChatBot(),
        '/forum': (context) => const Forum(),
      },
    );
  }
}