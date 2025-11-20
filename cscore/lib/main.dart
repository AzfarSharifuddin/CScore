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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Optional: allows students to view materials without logging in (keep as you had it)
  //await FirebaseAuth.instance.signInAnonymously();

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  // ✅ Initialize Supabase (just add your URL + anon key)
  await Supabase.initialize(
    url: 'https://pwvboweykmicdgsuxnad.supabase.co', // <-- replace
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB3dmJvd2V5a21pY2Rnc3V4bmFkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI0NTM2OTIsImV4cCI6MjA3ODAyOTY5Mn0.15hL7x_W3SfgdKGVLH-FClF4Msz0eDotf4Uy5llK9MQ', // <-- replace
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
