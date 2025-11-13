// quiz.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cscore/QuizModule/Models/quiz_model.dart';
import 'package:cscore/QuizModule/Services/quiz_service.dart';
import 'view_quiz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color mainColor = Color.fromRGBO(0, 70, 67, 1);

class QuizListPage extends StatelessWidget {
  const QuizListPage({super.key});

  String formatDeadline(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  Future<int> _fetchAttemptsLeft(String quizId, int maxAttempts) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return maxAttempts;
    final doc = await FirebaseFirestore.instance.collection('progress').doc(user.uid).collection('quizProgress').doc(quizId).get();
    if (!doc.exists) return maxAttempts;
    final data = doc.data()!;
    final prev = (data['attemptCount'] is num) ? (data['attemptCount'] as num).toInt() : 0;
    return (maxAttempts - prev) < 0 ? 0 : (maxAttempts - prev);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text("Quizzes", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: mainColor),
      body: StreamBuilder<List<QuizModel>>(
        stream: QuizService().fetchAllQuizzes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: mainColor));
          final quizzes = snapshot.data!;
          if (quizzes.isEmpty) return const Center(child: Text("No quizzes available."));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final q = quizzes[index];
              return FutureBuilder<int>(
                future: _fetchAttemptsLeft(q.id, q.maxAttempts),
                builder: (context, snapAttempts) {
                  final attemptsLeft = snapAttempts.data ?? q.maxAttempts;
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ViewQuizPage(quiz: q))),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0,4))]),
                      child: Row(children: [
                        ClipRRect(borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)), child: Image.asset(q.image, height: 100, width: 100, fit: BoxFit.cover)),
                        Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(q.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(q.category, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                          const SizedBox(height: 6),
                          Text("Duration: ${q.duration} min", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          Text("Deadline: ${formatDeadline(q.deadline)}", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 6),
                          Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: mainColor, borderRadius: BorderRadius.circular(8)), child: Text(q.quizType.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12))), const SizedBox(width: 10), Text("Attempts left: $attemptsLeft", style: const TextStyle(fontSize: 12, color: Colors.black54))])
                        ]))),
                        const Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18))
                      ]),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
