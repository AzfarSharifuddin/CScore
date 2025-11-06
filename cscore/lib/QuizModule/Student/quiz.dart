import 'package:flutter/material.dart';
import 'package:cscore/QuizModule/Data/quiz_data.dart';
import 'view_quiz.dart';

const mainColor = Color.fromRGBO(0, 70, 67, 1);

class QuizListPage extends StatefulWidget {
  const QuizListPage({super.key});

  @override
  State<QuizListPage> createState() => _QuizListPageState();
}

class _QuizListPageState extends State<QuizListPage> {
  void markAsAttempted(String title) {
    final index = sampleQuizzes.indexWhere((q) => q['title'] == title);
    if (index != -1) {
      setState(() {
        sampleQuizzes[index]['status'] = "Attempted";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Quizzes", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: mainColor,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sampleQuizzes.length,
        itemBuilder: (context, index) {
          final quiz = sampleQuizzes[index];

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ViewQuizPage(quizData: quiz),
                ),
              );

              if (result == true) markAsAttempted(quiz['title']);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    child: Image.asset(
                      quiz['image'],
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(quiz['title'],
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),

                          const SizedBox(height: 6),
                          Text(quiz['category'],
                              style: TextStyle(fontSize: 14, color: Colors.grey[600])),

                          const SizedBox(height: 8),
                          Text("Duration: ${quiz['duration']} min",
                              style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          Text("Deadline: ${formatDeadline(quiz['deadline'])}",
                              style: const TextStyle(fontSize: 12, color: Colors.black54)),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: mainColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  quiz['difficulty'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                quiz['status'],
                                style: TextStyle(
                                  color: quiz['status'] == "Attempted"
                                      ? Colors.blue
                                      : Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
