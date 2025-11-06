import 'package:flutter/material.dart';
import 'add_question.dart';

const mainColor = Color.fromRGBO(0, 70, 67, 1);

class CreateQuizPage extends StatefulWidget {
  const CreateQuizPage({super.key});

  @override
  State<CreateQuizPage> createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _numQuestionController = TextEditingController();

  String difficulty = "Easy";
  DateTime? selectedDeadline;

  // pick deadline date
  Future<void> _pickDeadline(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => selectedDeadline = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Create Quiz", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: mainColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Quiz Information",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: mainColor)),
              const SizedBox(height: 20),

              // Quiz Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Quiz Title",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Please enter a title" : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Please enter a description" : null,
              ),
              const SizedBox(height: 16),

              // Difficulty
              DropdownButtonFormField<String>(
                value: difficulty,
                decoration: const InputDecoration(
                  labelText: "Difficulty",
                  border: OutlineInputBorder(),
                ),
                items: ["Easy", "Medium", "Hard"]
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (value) => setState(() => difficulty = value!),
              ),
              const SizedBox(height: 16),

              // Duration
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: "Duration (minutes)",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter duration" : null,
              ),
              const SizedBox(height: 16),

              // Number of Questions
              TextFormField(
                controller: _numQuestionController,
                decoration: const InputDecoration(
                  labelText: "Number of Questions",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter number of questions" : null,
              ),
              const SizedBox(height: 16),

              // Deadline picker
              InkWell(
                onTap: () => _pickDeadline(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Deadline",
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedDeadline == null
                            ? "Select a deadline"
                            : "${selectedDeadline!.day}/${selectedDeadline!.month}/${selectedDeadline!.year}",
                      ),
                      const Icon(Icons.calendar_today, color: mainColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final quizInfo = {
                        'title': _titleController.text,
                        'description': _descriptionController.text,
                        'difficulty': difficulty,
                        'duration': int.tryParse(_durationController.text) ?? 0,
                        'deadline': selectedDeadline?.toIso8601String(),
                        'numQuestions': int.tryParse(_numQuestionController.text) ?? 0,
                      };

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddQuestionPage(quizInfo: quizInfo),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "Continue",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
