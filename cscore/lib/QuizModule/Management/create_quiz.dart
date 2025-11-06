import 'package:flutter/material.dart';
import 'package:cscore/QuizModule/Data/quiz_data.dart';
import 'add_question.dart';

const mainColor = Color.fromRGBO(0, 70, 67, 1);

class CreateQuizPage extends StatefulWidget {
  const CreateQuizPage({super.key});

  @override
  State<CreateQuizPage> createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  String difficulty = "Easy";
  int duration = 10;
  DateTime? deadline;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Create Quiz"),
        backgroundColor: mainColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text("Quiz Title"),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter quiz title",
              ),
            ),
            const SizedBox(height: 16),

            const Text("Description"),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter description",
              ),
            ),
            const SizedBox(height: 16),

            const Text("Difficulty"),
            DropdownButtonFormField(
              value: difficulty,
              items: ["Easy", "Medium", "Hard"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => difficulty = v!),
            ),
            const SizedBox(height: 16),

            const Text("Duration (minutes)"),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onChanged: (v) => duration = int.tryParse(v) ?? 10,
            ),
            const SizedBox(height: 16),

            const Text("Deadline"),
            OutlinedButton(
              onPressed: () async {
                final selected = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                  initialDate: DateTime.now(),
                );

                if (selected != null) {
                  setState(() {
                    deadline = selected;
                  });
                }
              },
              child: Text(
                deadline == null
                    ? "Select Deadline"
                    : "Deadline: ${formatDeadline(deadline!)}",
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: mainColor),
              onPressed: () {
                if (titleCtrl.text.isEmpty ||
                    descCtrl.text.isEmpty ||
                    deadline == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Fill all fields")),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddQuestionsPage(
                      title: titleCtrl.text,
                      description: descCtrl.text,
                      difficulty: difficulty,
                      duration: duration,
                      deadline: deadline!,
                    ),
                  ),
                );
              },
              child: const Text("Continue", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}
