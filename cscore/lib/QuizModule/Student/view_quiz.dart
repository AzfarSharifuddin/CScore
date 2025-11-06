import 'package:flutter/material.dart';
import 'attempt_quiz.dart';

const mainColor = Color.fromRGBO(0, 70, 67, 1);

class ViewQuizPage extends StatelessWidget {
  final Map<String, dynamic> quizData;
  const ViewQuizPage({super.key, required this.quizData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Stack(
            children: [
              Image.asset(
                quizData['image'],
                height: 230,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Container(
                height: 230,
                width: double.infinity,
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
                  quizData['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        label: Text(quizData['category'],
                            style: const TextStyle(color: Colors.white)),
                        backgroundColor: mainColor,
                      ),
                      Text(
                        quizData['difficulty'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: mainColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text("20 Questions • 30 Minutes",
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  Text(
                    quizData['description'],
                    style: const TextStyle(fontSize: 16, height: 1.4),
                  ),
                  const Spacer(),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      label: const Text("Start Quiz",
                          style: TextStyle(fontSize: 18, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
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
          ),
        ],
      ),
    );
  }
}
