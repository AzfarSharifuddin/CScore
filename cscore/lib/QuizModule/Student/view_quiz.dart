// view_quiz.dart
import 'package:flutter/material.dart';
import 'package:cscore/QuizModule/Models/quiz_model.dart';
import 'attempt_quiz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color mainColor = Color.fromRGBO(0, 70, 67, 1);

class ViewQuizPage extends StatelessWidget {
  final QuizModel quiz;
  const ViewQuizPage({super.key, required this.quiz});

  Future<int> _attemptsLeft() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return quiz.maxAttempts;
    final doc = await FirebaseFirestore.instance.collection('progress').doc(user.uid).collection('quizProgress').doc(quiz.id).get();
    if (!doc.exists) return quiz.maxAttempts;
    final data = doc.data()!;
    final prev = (data['attemptCount'] is num) ? (data['attemptCount'] as num).toInt() : 0;
    final left = quiz.maxAttempts - prev;
    return left < 0 ? 0 : left;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(children: [
        Stack(children: [
          Image.asset(quiz.image, height: 230, width: double.infinity, fit: BoxFit.cover),
          Container(height: 230, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.6), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter))),
          Positioned(top: 40, left: 16, child: CircleAvatar(backgroundColor: Colors.white70, child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)))),
          Positioned(bottom: 20, left: 20, right: 20, child: Text(quiz.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold))),
        ]),
        Expanded(child: Container(padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Chip(label: Text(quiz.category, style: const TextStyle(color: Colors.white)), backgroundColor: mainColor),
          const SizedBox(height: 12),
          Text("Type: ${quiz.quizType}", style: const TextStyle(fontWeight: FontWeight.bold, color: mainColor)),
          const SizedBox(height: 12),
          Text("Duration: ${quiz.duration} minutes", style: const TextStyle(color: Colors.black87)),
          Text("Deadline: ${quiz.deadline.day}/${quiz.deadline.month}/${quiz.deadline.year}", style: const TextStyle(color: Colors.black87)),
          const SizedBox(height: 16),
          Text(quiz.description, style: const TextStyle(fontSize: 16, height: 1.4)),
          const Spacer(),
          FutureBuilder<int>(
            future: _attemptsLeft(),
            builder: (context, snap) {
              final left = snap.data ?? quiz.maxAttempts;
              return Column(children: [
                if (left <= 0) const Text("No attempts left for this quiz.", style: TextStyle(color: Colors.red)),
                Center(child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: Text(left <= 0 ? "No Attempts" : "Start Quiz", style: const TextStyle(fontSize: 18, color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: left <= 0 ? Colors.grey : mainColor, padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: left <= 0 ? null : () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AttemptQuizPage(quiz: quiz)));
                  },
                )),
                const SizedBox(height: 8),
                Text("Attempts left: $left"),
              ]);
            },
          ),
        ])))
      ]),
    );
  }
}
