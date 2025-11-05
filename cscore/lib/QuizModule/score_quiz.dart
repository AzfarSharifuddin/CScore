import 'package:flutter/material.dart';
import 'quiz.dart';

class ScoreQuizPage extends StatelessWidget {
  final String title;
  final int score;
  final int total;

  const ScoreQuizPage({super.key, required this.title, required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    double percentage = (score / total) * 100;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quiz Result"),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.green,
                child: Text(
                  "$score/$total",
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Congratulations, Great job Azfar for completing the quiz!",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              Text("Score: ${percentage.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const QuizListPage()),
                    (route) => false),
                child: const Text("Done", style: TextStyle(fontSize: 18)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
