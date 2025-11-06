import 'package:flutter/material.dart';
import 'package:cscore/QuizModule/Models/quiz_model.dart';
import 'attempt_quiz.dart';

const Color mainColor = Color.fromRGBO(0, 70, 67, 1);

class ViewQuizPage extends StatelessWidget {
  final QuizModel quiz;

  const ViewQuizPage({super.key, required this.quiz});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Header Image
          Stack(
            children: [
              Image.asset(
                quiz.image,
                height: 230,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Container(
                height: 230,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Positioned(
                top: 40,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.white70,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Text(
                  quiz.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Body
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Chip(
                    label: Text(quiz.category,
                        style: const TextStyle(color: Colors.white)),
                    backgroundColor: mainColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Difficulty: ${quiz.difficulty}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: mainColor),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Duration: ${quiz.duration} minutes",
                    style: const TextStyle(color: Colors.black87),
                  ),
                  Text(
                    "Deadline: ${quiz.deadline.day}/${quiz.deadline.month}/${quiz.deadline.year}",
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    quiz.description,
                    style: const TextStyle(fontSize: 16, height: 1.4),
                  ),
                  const Spacer(),
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      label: const Text("Start Quiz",
                          style:
                              TextStyle(fontSize: 18, color: Colors.white)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AttemptQuizPage(quiz: quiz),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
