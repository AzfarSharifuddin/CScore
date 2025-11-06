import 'package:flutter/material.dart';
import 'package:cscore/QuizModule/Models/quiz_model.dart';
import 'package:cscore/QuizModule/Services/quiz_service.dart';

const Color mainColor = Color.fromRGBO(0, 70, 67, 1);

class ManageQuizzesPage extends StatelessWidget {
  const ManageQuizzesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: mainColor,
        title: const Text("Manage Quizzes"),
      ),
      body: StreamBuilder<List<QuizModel>>(
        stream: QuizService().fetchTeacherQuizzes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: mainColor));
          }

          final quizzes = snapshot.data!;

          if (quizzes.isEmpty) {
            return const Center(child: Text("No quizzes created yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final quiz = quizzes[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      quiz.image,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(quiz.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      "Deadline: ${quiz.deadline.day}/${quiz.deadline.month}/${quiz.deadline.year}\n"
                      "Questions: ${quiz.numQuestions}"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
