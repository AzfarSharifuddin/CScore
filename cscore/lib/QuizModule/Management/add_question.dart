import 'package:flutter/material.dart';
import 'package:cscore/QuizModule/Data/quiz_data.dart';
import 'manage_quiz.dart';

const mainColor = Color.fromRGBO(0, 70, 67, 1);

class AddQuestionsPage extends StatefulWidget {
  final String title;
  final String description;
  final String difficulty;
  final int duration;
  final DateTime deadline;

  const AddQuestionsPage({
    super.key,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.duration,
    required this.deadline,
  });

  @override
  State<AddQuestionsPage> createState() => _AddQuestionsPageState();
}

class _AddQuestionsPageState extends State<AddQuestionsPage> {
  List<Map<String, dynamic>> questions = [];

  final qCtrl = TextEditingController();
  final op1 = TextEditingController();
  final op2 = TextEditingController();
  final op3 = TextEditingController();
  final op4 = TextEditingController();

  int correctIndex = 0;
  bool isObjective = true;

  void addQuestion() {
    if (qCtrl.text.isEmpty) return;

    if (isObjective) {
      questions.add({
        'type': 'objective',
        'question': qCtrl.text,
        'options': [op1.text, op2.text, op3.text, op4.text],
        'answer': correctIndex,
      });
    } else {
      questions.add({
        'type': 'subjective',
        'question': qCtrl.text,
      });
    }

    qCtrl.clear();
    op1.clear();
    op2.clear();
    op3.clear();
    op4.clear();

    setState(() {});
  }

  void saveQuiz() {
    sampleQuizzes.add({
      'title': widget.title,
      'category': "General",
      'difficulty': widget.difficulty,
      'status': "Not Attempted",
      'image': 'assets/quiz_assets/html.jpg',
      'description': widget.description,
      'duration': widget.duration,
      'deadline': widget.deadline,
      'questions': questions,
    });

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ManageQuizPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Questions"),
        backgroundColor: mainColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Row(
              children: [
                ChoiceChip(
                  label: const Text("Objective"),
                  selected: isObjective,
                  onSelected: (_) => setState(() => isObjective = true),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text("Subjective"),
                  selected: !isObjective,
                  onSelected: (_) => setState(() => isObjective = false),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Text("Question"),
            TextField(
              controller: qCtrl,
              maxLines: 2,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),

            if (isObjective) ...[
              const SizedBox(height: 16),
              const Text("Options"),
              TextField(controller: op1, decoration: const InputDecoration(hintText: "Option 1")),
              TextField(controller: op2, decoration: const InputDecoration(hintText: "Option 2")),
              TextField(controller: op3, decoration: const InputDecoration(hintText: "Option 3")),
              TextField(controller: op4, decoration: const InputDecoration(hintText: "Option 4")),
              const SizedBox(height: 10),
              const Text("Correct Answer Index (0-3)"),
              TextField(
                keyboardType: TextInputType.number,
                onChanged: (v) => correctIndex = int.tryParse(v) ?? 0,
              ),
            ],

            const SizedBox(height: 18),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: mainColor),
              onPressed: addQuestion,
              child: const Text("Add Question", style: TextStyle(color: Colors.white)),
            ),

            const SizedBox(height: 24),

            if (questions.isNotEmpty)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: saveQuiz,
                child: const Text(
                  "Save Quiz",
                  style: TextStyle(color: Colors.white),
                ),
              )
          ],
        ),
      ),
    );
  }
}
