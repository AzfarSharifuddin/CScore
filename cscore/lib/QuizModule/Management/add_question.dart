// add_question.dart
import 'package:flutter/material.dart';
import 'package:cscore/QuizModule/Models/quiz_model.dart';
import 'package:cscore/QuizModule/Services/quiz_service.dart';
import 'success_quiz.dart';

const Color mainColor = Color.fromRGBO(0, 70, 67, 1);

class AddQuestionsPage extends StatefulWidget {
  final String quizId;
  final int numQuestions;
  const AddQuestionsPage({super.key, required this.quizId, required this.numQuestions});

  @override
  State<AddQuestionsPage> createState() => _AddQuestionsPageState();
}

class _AddQuestionsPageState extends State<AddQuestionsPage> {
  List<QuestionModel> questions = [];

  /// NEW: Persistent controllers
  late List<TextEditingController> questionControllers;
  late List<List<TextEditingController>> optionControllers;

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
      ),
    );

    // Initialize controllers
    questionControllers = List.generate(
      widget.numQuestions,
      (i) => TextEditingController(),
    );

    optionControllers = List.generate(
      widget.numQuestions,
      (i) => [],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(title: const Text("Add Questions"), backgroundColor: mainColor),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.numQuestions,
        itemBuilder: (context, index) => QuestionCard(
          index: index,
          question: questions[index],
          controller: questionControllers[index],
          optionControllers: optionControllers[index],
          onUpdate: (updated) {
            setState(() => questions[index] = updated);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: mainColor,
        label: const Text("Save Quiz"),
        onPressed: saveQuiz,
      ),
    );
  }

  void saveQuiz() async {
    final success = await QuizService().addQuestionsToQuiz(widget.quizId, questions);
    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const QuizSuccessPage(title: "Quiz Created")),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to save quiz. Please try again.")));
    }
  }
}

/// KEEP ALIVE WIDGET WRAPPER
class QuestionCard extends StatefulWidget {
  final int index;
  final QuestionModel question;
  final TextEditingController controller;
  final List<TextEditingController> optionControllers;
  final Function(QuestionModel) onUpdate;

  const QuestionCard({
    super.key,
    required this.index,
    required this.question,
    required this.controller,
    required this.optionControllers,
    required this.onUpdate,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final q = widget.question;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Question ${widget.index + 1}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // Question type
            DropdownButton<String>(
              value: q.type,
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  widget.onUpdate(
                    QuestionModel(
                      type: v,
                      question: q.question,
                      options: v == "objective" ? (q.options ?? []) : null,
                      answer: v == "objective" ? q.answer : null,
                      expectedAnswer: v == "subjective" ? q.expectedAnswer : null,
                      aiEvaluated: v == "subjective" ? false : null,
                    ),
                  );
                });
              },
              items: const [
                DropdownMenuItem(value: "objective", child: Text("Multiple Choice")),
                DropdownMenuItem(value: "subjective", child: Text("Subjective")),
              ],
            ),

            const SizedBox(height: 10),

            // Question text controller
            TextField(
              controller: widget.controller,
              decoration: const InputDecoration(labelText: "Question Text"),
              onChanged: (v) {
                widget.onUpdate(
                  QuestionModel(
                    type: q.type,
                    question: v,
                    options: q.options,
                    answer: q.answer,
                    expectedAnswer: q.expectedAnswer,
                    aiEvaluated: q.aiEvaluated,
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            if (q.type == "objective") buildMCQSection(q),
            if (q.type == "subjective") buildSubjectiveSection(q),
          ],
        ),
      ),
    );
  }

  Widget buildMCQSection(QuestionModel q) {
    final opts = q.options ?? [];

    // Ensure option controllers match length
    while (widget.optionControllers.length < opts.length) {
      widget.optionControllers.add(TextEditingController());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Options:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),

        // Dynamic options
        ...List.generate(opts.length, (i) {
          final c = widget.optionControllers[i];
          c.text = opts[i];

          return Row(
            children: [
              Expanded(
                child: TextField(
                  controller: c,
                  decoration: InputDecoration(labelText: "Option ${i + 1}"),
                  onChanged: (v) {
                    opts[i] = v;
                    widget.onUpdate(
                      QuestionModel(
                        type: "objective",
                        question: q.question,
                        options: opts,
                        answer: q.answer,
                      ),
                    );
                  },
                ),
              ),
              Radio<int>(
                value: i,
                groupValue: q.answer,
                onChanged: (v) {
                  setState(() {
                    widget.onUpdate(
                      QuestionModel(
                        type: "objective",
                        question: q.question,
                        options: opts,
                        answer: v,
                      ),
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
              opts.add("");
              widget.optionControllers.add(TextEditingController());

              widget.onUpdate(
                QuestionModel(
                  type: "objective",
                  question: q.question,
                  options: opts,
                  answer: q.answer,
                ),
              );
            });
          },
        ),
      ],
    );
  }

  Widget buildSubjectiveSection(QuestionModel q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Expected Answer (for AI marking):",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          maxLines: 3,
          decoration:
              const InputDecoration(labelText: "Expected Answer (Teacher’s Answer)"),
          onChanged: (v) {
            widget.onUpdate(
              QuestionModel(
                type: "subjective",
                question: q.question,
                options: null,
                answer: null,
                expectedAnswer: v,
                aiEvaluated: false,
              ),
            );
          },
        ),
      ],
    );
  }
}
