import 'package:flutter/material.dart';
import 'quiz.dart';

class ScoreQuizPage extends StatelessWidget {
  final String title;
  final int score;
  final int total;
  final List<Map<String, dynamic>> subjectiveAnswers;

  const ScoreQuizPage({
    super.key,
    required this.title,
    required this.score,
    required this.total,
    required this.subjectiveAnswers,
  });

  @override
  Widget build(BuildContext context) {
    double percentage = (score / total) * 100;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("Quiz Result"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.green,
              child: Text(
                "$score/$total",
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              percentage >= 80
                  ? "🏆 Excellent Work!"
                  : percentage >= 50
                      ? "🎉 Great Job!"
                      : "Keep Practicing 💪",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "You completed the $title quiz.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Show subjective answers
            if (subjectiveAnswers.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Your Written Answers:",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...subjectiveAnswers.map((q) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(q['question'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text(q['answer'].isEmpty
                                  ? "(No answer submitted)"
                                  : q['answer']),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const QuizListPage()),
                  (route) => false),
              child: const Text("Done", style: TextStyle(fontSize: 18)),
            )
          ],
        ),
      ),
    );
  }
}
