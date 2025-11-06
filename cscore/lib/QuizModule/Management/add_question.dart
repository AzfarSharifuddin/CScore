import 'package:flutter/material.dart';
import 'package:cscore/QuizModule/Models/quiz_model.dart';
import 'package:cscore/QuizModule/Services/quiz_service.dart';
import 'success_quiz.dart';

const Color mainColor = Color.fromRGBO(0, 70, 67, 1);

class AddQuestionsPage extends StatefulWidget {
  final String quizId;
  final int numQuestions;

  const AddQuestionsPage({
    super.key,
    required this.quizId,
    required this.numQuestions,
  });

  @override
  State<AddQuestionsPage> createState() => _AddQuestionsPageState();
}

class _AddQuestionsPageState extends State<AddQuestionsPage> {
  List<QuestionModel> questions = [];

  @override
  void initState() {
    super.initState();
    questions = List.generate(
      widget.numQuestions,
      (index) => QuestionModel(
        type: "objective",
        question: "",
        options: [],
        answer: 0,
        expectedAnswer: "",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text("Add Questions"),
        backgroundColor: mainColor,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.numQuestions,
        itemBuilder: (context, index) => buildQuestionCard(index),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: mainColor,
        label: const Text("Save Quiz"),
        onPressed: saveQuiz,
      ),
    );
  }

  Widget buildQuestionCard(int index) {
    final question = questions[index];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Question ${index + 1}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            DropdownButton<String>(
              value: question.type,
              onChanged: (v) {
                setState(() {
                  questions[index] = QuestionModel(
                    type: v!,
                    question: question.question,
                    options: v == "objective" ? [] : null,
                    answer: v == "objective" ? 0 : null,
                    expectedAnswer: "",
                  );
                });
              },
              items: const [
                DropdownMenuItem(value: "objective", child: Text("Multiple Choice")),
                DropdownMenuItem(value: "subjective", child: Text("Subjective")),
              ],
            ),

            const SizedBox(height: 10),

            TextField(
              decoration: const InputDecoration(labelText: "Question Text"),
              onChanged: (v) {
                questions[index] = QuestionModel(
                  type: question.type,
                  question: v,
                  options: question.options,
                  answer: question.answer,
                  expectedAnswer: question.expectedAnswer,
                );
              },
            ),

            const SizedBox(height: 10),

            if (question.type == "objective") buildMCQSection(index),
            if (question.type == "subjective") buildSubjectiveSection(index),
          ],
        ),
      ),
    );
  }

  Widget buildMCQSection(int index) {
    final question = questions[index];
    final options = question.options ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Options:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),

        ...List.generate(options.length, (i) {
          return Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(labelText: "Option ${i + 1}"),
                  onChanged: (v) {
                    options[i] = v;
                  },
                ),
              ),
              Radio<int>(
                value: i,
                groupValue: question.answer,
                onChanged: (v) {
                  setState(() {
                    questions[index] = QuestionModel(
                      type: "objective",
                      question: question.question,
                      options: options,
                      answer: i,
                      expectedAnswer: "",
                    );
                  });
                },
              ),
            ],
          );
        }),

        TextButton(
          child: const Text("Add Option"),
          onPressed: () {
            setState(() {
              options.add("");
              questions[index] = QuestionModel(
                type: "objective",
                question: question.question,
                options: options,
                answer: question.answer,
                expectedAnswer: "",
              );
            });
          },
        ),
      ],
    );
  }

  Widget buildSubjectiveSection(int index) {
    final question = questions[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Expected Answer (for AI marking):",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(
            labelText: "Expected Answer (Teacher’s Answer)",
          ),
          maxLines: 3,
          onChanged: (v) {
            questions[index] = QuestionModel(
              type: "subjective",
              question: question.question,
              options: null,
              answer: null,
              expectedAnswer: v,
            );
          },
        ),
      ],
    );
  }

  void saveQuiz() async {
    final success = await QuizService().addQuestionsToQuiz(widget.quizId, questions);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const QuizSuccessPage(title: "Quiz Created"),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save quiz. Please try again.")),
      );
    }
  }
}
