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
  String difficulty = "Easy";
  int duration = 10;
  int numQuestions = 1;
  DateTime? deadline;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Create Quiz"),
        backgroundColor: mainColor,
      ),
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

              // Difficulty Dropdown
              DropdownButtonFormField<String>(
                value: difficulty,
                decoration: const InputDecoration(labelText: "Difficulty"),
                items: ["Easy", "Medium", "Hard"]
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => difficulty = v!,
              ),

              const SizedBox(height: 10),

              // Duration
              TextFormField(
                decoration: const InputDecoration(labelText: "Duration (minutes)"),
                keyboardType: TextInputType.number,
                onChanged: (v) => duration = int.parse(v),
              ),

              const SizedBox(height: 10),

              // Number of Questions
              TextFormField(
                decoration:
                    const InputDecoration(labelText: "Number of Questions"),
                keyboardType: TextInputType.number,
                onChanged: (v) => numQuestions = int.parse(v),
              ),

              const SizedBox(height: 10),

              // Deadline picker
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: mainColor),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      deadline = picked;
                    });
                  }
                },
                child: Text(deadline == null
                    ? "Select Deadline"
                    : "Deadline: ${DateFormat('dd/MM/yyyy').format(deadline!)}"),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  if (deadline == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select deadline.")));
                    return;
                  }

                  final quizId = await QuizService().createQuizMetadata(
                    title: title,
                    description: description,
                    category: category,
                    difficulty: difficulty,
                    duration: duration,
                    deadline: deadline!,
                    numQuestions: numQuestions,
                  );

                  if (quizId != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddQuestionsPage(
                          quizId: quizId,
                          numQuestions: numQuestions,
                        ),
                      ),
                    );
                  }
                },
                child: const Text("Continue"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Simple field builder
  Widget buildTextField(String label, Function(String?) onSaved) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
      onChanged: onSaved,
    );
  }
}
