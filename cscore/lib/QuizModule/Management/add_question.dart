import 'package:flutter/material.dart';
import 'package:cscore/QuizModule/Data/quiz_data.dart';
import 'success_quiz.dart';

const mainColor = Color.fromRGBO(0, 70, 67, 1);

class AddQuestionPage extends StatefulWidget {
  final Map<String, dynamic> quizInfo;

  const AddQuestionPage({super.key, required this.quizInfo});

  @override
  State<AddQuestionPage> createState() => _AddQuestionPageState();
}

class _AddQuestionPageState extends State<AddQuestionPage> {
  final _formKey = GlobalKey<FormState>();
  int currentQuestion = 1;
  String questionType = "Objective";

  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers =
      List.generate(4, (_) => TextEditingController());
  int correctAnswerIndex = 0;
  final TextEditingController _subjectiveAnswerController =
      TextEditingController();

  final List<Map<String, dynamic>> _questions = [];

  void _saveQuestion() {
    if (!_formKey.currentState!.validate()) return;

    if (questionType == "Objective") {
      _questions.add({
        'type': 'objective',
        'question': _questionController.text,
        'options': _optionControllers.map((c) => c.text).toList(),
        'answer': correctAnswerIndex,
      });
    } else {
      _questions.add({
        'type': 'subjective',
        'question': _questionController.text,
      });
    }

    // Clear input fields for next question
    _questionController.clear();
    for (var controller in _optionControllers) {
      controller.clear();
    }
    _subjectiveAnswerController.clear();

    setState(() {
      currentQuestion++;
      questionType = "Objective";
      correctAnswerIndex = 0;
    });
  }

  void _submitQuiz() {
    // Combine quiz info + questions
    final newQuiz = {
      'title': widget.quizInfo['title'],
      'category': 'Custom Quiz',
      'difficulty': widget.quizInfo['difficulty'],
      'status': 'Not Attempted',
      'image': 'assets/quiz_assets/html.jpg',
      'description': widget.quizInfo['description'],
      'duration': widget.quizInfo['duration'],
      'deadline': widget.quizInfo['deadline'],
      'questions': _questions,
    };

    // Add to shared list
    sampleQuizzes.add(newQuiz);

    // Navigate to success page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SuccessQuizPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Add Questions"),
        backgroundColor: mainColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Question $currentQuestion of ${widget.quizInfo['numQuestions']}",
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: mainColor),
              ),
              const SizedBox(height: 20),

              // Question Type Toggle
              Row(
                children: [
                  const Text("Question Type: ",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: questionType,
                    items: ["Objective", "Subjective"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => questionType = val!),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Question Text
              TextFormField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: "Question",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter a question" : null,
              ),
              const SizedBox(height: 20),

              if (questionType == "Objective") ...[
                const Text("Answer Options:",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),

                // Options + Correct Answer Selector
                for (int i = 0; i < 4; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: i,
                          groupValue: correctAnswerIndex,
                          activeColor: mainColor,
                          onChanged: (val) =>
                              setState(() => correctAnswerIndex = val!),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _optionControllers[i],
                            decoration: InputDecoration(
                              labelText: "Option ${i + 1}",
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? "Enter option ${i + 1}"
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],

              if (questionType == "Subjective") ...[
                const Text("Short Answer (optional for teacher reference):",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                TextField(
                  controller: _subjectiveAnswerController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "Enter a sample answer (optional)",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 30),

              // Add or Submit Button
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (currentQuestion <
                          widget.quizInfo['numQuestions']) {
                        _saveQuestion();
                      } else {
                        _saveQuestion();
                        _submitQuiz();
                      }
                    }
                  },
                  child: Text(
                    currentQuestion < widget.quizInfo['numQuestions']
                        ? "Next Question"
                        : "Finish & Add Quiz",
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
