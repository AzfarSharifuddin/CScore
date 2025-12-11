// create_quiz.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cscore/QuizModule/Services/quiz_service.dart';
import 'add_question.dart';

const Color mainColor = Color.fromRGBO(0, 70, 67, 1);

class CreateQuizPage extends StatefulWidget {
  const CreateQuizPage({super.key});
  @override
  State<CreateQuizPage> createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage> {
  final _formKey = GlobalKey<FormState>();
  String title = "";
  String description = "";
  String category = "";
  String quizType = "exercise";
  int duration = 10;
  int numQuestions = 1;
  int maxAttempts = 1; // new
  DateTime? deadline;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text("Create Quiz"), backgroundColor: mainColor),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              buildTextField("Title", (v) => title = v!),
              buildTextField("Description", (v) => description = v!),
              buildTextField("Category", (v) => category = v!),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: quizType,
                decoration: const InputDecoration(labelText: "Quiz Type"),
                items: const [
                  DropdownMenuItem(value: "exercise", child: Text("Exercise")),
                  DropdownMenuItem(value: "exam", child: Text("Exam")),
                ],
                onChanged: (v) => quizType = v ?? "exercise",
              ),

              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(labelText: "Duration (minutes)"),
                keyboardType: TextInputType.number,
                onChanged: (v) => duration = int.tryParse(v) ?? 10,
              ),

              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(labelText: "Number of Questions"),
                keyboardType: TextInputType.number,
                onChanged: (v) => numQuestions = int.tryParse(v) ?? 1,
              ),

              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(labelText: "Max Attempts (leave blank for 1)"),
                keyboardType: TextInputType.number,
                onChanged: (v) => maxAttempts = int.tryParse(v) ?? 1,
              ),

              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: mainColor),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => deadline = picked);
                },
                child: Text(
                  deadline == null ? "Select Deadline" : "Deadline: ${DateFormat('dd/MM/yyyy').format(deadline!)}",
                  style: const TextStyle(color: Colors.white),
                ),
              ),

              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: mainColor, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  if (deadline == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select deadline.")));
                    return;
                  }
                  final quizId = await QuizService().createQuizMetadata(
                    title: title,
                    description: description,
                    category: category,
                    quizType: quizType,
                    duration: duration,
                    deadline: deadline!,
                    numQuestions: numQuestions,
                    maxAttempts: maxAttempts,
                  );
                  if (quizId != null) {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AddQuestionsPage(quizId: quizId, numQuestions: numQuestions)));
                  }
                },
                child: const Text("Continue", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String label, Function(String?) onSaved) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
      onChanged: onSaved,
    );
  }
}
