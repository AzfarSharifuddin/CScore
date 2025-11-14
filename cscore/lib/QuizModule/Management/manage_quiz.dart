import 'package:flutter/material.dart';
import 'package:cscore/QuizModule/Models/quiz_model.dart';
import 'package:cscore/QuizModule/Services/quiz_service.dart';
import 'view_quiz_attempts.dart';
import 'package:cscore/QuizModule/Management/create_quiz.dart';

const Color mainColor = Color.fromRGBO(0, 70, 67, 1);

class ManageQuizzesPage extends StatelessWidget {
  const ManageQuizzesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(backgroundColor: mainColor, title: const Text("Manage Quizzes")),
      body: StreamBuilder<List<QuizModel>>(
        stream: QuizService().fetchTeacherQuizzes(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final list = snap.data!;
          if (list.isEmpty) return const Center(child: Text("No quizzes created yet."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final quiz = list[i];
              return GestureDetector(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ViewQuizAttemptsPage(quizId: quiz.id,
  quizTitle: quiz.title,)));
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                      )
                    ],
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        quiz.image,
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(quiz.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        "Deadline: ${quiz.deadline.day}/${quiz.deadline.month}/${quiz.deadline.year}\nQuestions: ${quiz.numQuestions}"),
                  ),
                ),
              );
            },
          );
        },
      ),

      // CREATE QUIZ BUTTON
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: mainColor,
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const CreateQuizPage()));
        },
        label: const Text("Create Quiz", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
