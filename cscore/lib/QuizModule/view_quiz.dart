import 'package:flutter/material.dart';
import 'attempt_quiz.dart';

class ViewQuizPage extends StatelessWidget {
  final Map<String, dynamic> quizData;
  const ViewQuizPage({super.key, required this.quizData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(quizData['title']),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/quiz_banner.jpg', // replace with your banner asset
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(quizData['category'], style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(quizData['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Chip(label: Text(quizData['difficulty'])),
              ],
            ),
            const SizedBox(height: 8),
            const Text("20 Questions • 30 Minutes", style: TextStyle(color: Colors.grey)),
            const Divider(height: 32),
            Text(quizData['description'], style: const TextStyle(fontSize: 16)),
            const Spacer(),
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text("Start Quiz", style: TextStyle(fontSize: 18)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AttemptQuizPage(
                        title: quizData['title'],
                        questions: quizData['questions'],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
