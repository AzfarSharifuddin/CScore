import 'package:cscore/AIModule/ai_chatbox.dart';
import 'package:cscore/DashboardModule/dashboard.dart';
import 'package:cscore/ForumModule/forum.dart';
import 'package:cscore/LearningModule/learning.dart';
import 'package:cscore/QuizModule/quiz.dart';
import 'package:cscore/AccountModule/screen/login.dart'; // ✅ New Login Page
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cscore/firebase_options.dart';

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
      title: 'CScore+',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 2,
        ),
      ),
      
      // ✅ Start from Login Page
      initialRoute: '/login',

      routes: {
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const Dashboard(),
        '/learning': (context) => const Learning(),
        '/quiz': (context) => const Quiz(),
        '/ai': (context) => const AiChatBot(),
        '/forum': (context) => const Forum(),
      },
    );
  }
}
