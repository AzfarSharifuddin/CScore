import 'package:flutter/material.dart';
import 'package:cscore/QuizModule/Data/quiz_data.dart';
import 'create_quiz.dart';

const mainColor = Color.fromRGBO(0, 70, 67, 1);

class ManageQuizPage extends StatefulWidget {
  const ManageQuizPage({super.key});

  @override
  State<ManageQuizPage> createState() => _ManageQuizPageState();
}

class _ManageQuizPageState extends State<ManageQuizPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Manage Quizzes"),
        backgroundColor: mainColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateQuizPage()),
              );
              setState(() {});
            },
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sampleQuizzes.length,
        itemBuilder: (context, index) {
          final quiz = sampleQuizzes[index];
          final DateTime deadline = quiz['deadline'];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quiz['title'],
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                Text("Category: ${quiz['category']}"),
                Text("Difficulty: ${quiz['difficulty']}"),
                Text("Duration: ${quiz['duration']} minutes"),
                Text("Deadline: ${formatDeadline(deadline)}"),
                Text("Questions: ${quiz['questions'].length}"),

                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        child: const Text("Edit"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        child: const Text("Delete"),
                      ),
                    )
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
