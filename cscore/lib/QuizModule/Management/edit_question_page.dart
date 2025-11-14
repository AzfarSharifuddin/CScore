// lib/QuizModule/Management/edit_question_page.dart
import 'package:flutter/material.dart';
import 'package:cscore/QuizModule/Models/quiz_model.dart';
import 'package:cscore/QuizModule/Services/quiz_service.dart';

const Color mainColor = Color.fromRGBO(0, 70, 67, 1);

class EditQuestionPage extends StatefulWidget {
  final String quizId;
  final List<QuestionModel> initialQuestions;

  const EditQuestionPage({super.key, required this.quizId, required this.initialQuestions});

  @override
  State<EditQuestionPage> createState() => _EditQuestionPageState();
}

class _EditQuestionPageState extends State<EditQuestionPage> {
  late List<QuestionModel> questions;

  @override
  void initState() {
    super.initState();
    // make a copy to edit
    questions = widget.initialQuestions.map((q) {
      return QuestionModel(
        type: q.type,
        question: q.question,
        options: q.options == null ? null : List<String>.from(q.options!),
        answer: q.answer,
        expectedAnswer: q.expectedAnswer,
        aiEvaluated: q.aiEvaluated,
      );
    }).toList();
  }

  void _addQuestion() {
    setState(() {
      questions.add(QuestionModel(type: 'objective', question: '', options: ['',''], answer: 0));
    });
  }

  Future<void> _saveQuestions() async {
    final success = await QuizService().addQuestionsToQuiz(widget.quizId, questions);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Questions saved.")));
        Navigator.pop(context, true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to save questions.")));
    }
  }

  Widget _buildObjectiveEditor(int idx) {
    final q = questions[idx];
    final opts = q.options ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < opts.length; i++)
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: opts[i],
                  decoration: InputDecoration(labelText: "Option ${i+1}"),
                  onChanged: (v) => opts[i] = v,
                ),
              ),
              Radio<int>(
                value: i,
                groupValue: q.answer ?? 0,
                onChanged: (v) {
                  setState(() {
                    questions[idx] = QuestionModel(
                      type: 'objective',
                      question: q.question,
                      options: opts,
                      answer: v,
                    );
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  setState(() {
                    opts.removeAt(i);
                    // if answer index out of range, reset to 0
                    final newAnswer = (q.answer != null && q.answer! < opts.length) ? q.answer : 0;
                    questions[idx] = QuestionModel(
                      type: 'objective',
                      question: q.question,
                      options: opts,
                      answer: newAnswer,
                    );
                  });
                },
              )
            ],
          ),
        TextButton(onPressed: () {
          setState(() {
            opts.add('');
            questions[idx] = QuestionModel(
              type: 'objective',
              question: q.question,
              options: opts,
              answer: q.answer,
            );
          });
        }, child: const Text("Add Option"))
      ],
    );
  }

  Widget _buildSubjectiveEditor(int idx) {
    final q = questions[idx];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: q.expectedAnswer ?? '',
          decoration: const InputDecoration(labelText: "Expected Answer (teacher)"),
          maxLines: 3,
          onChanged: (v) {
            questions[idx] = QuestionModel(
              type: 'subjective',
              question: q.question,
              expectedAnswer: v,
              aiEvaluated: q.aiEvaluated ?? false,
            );
          },
        ),
        Row(
          children: [
            const Text("AI Evaluated: "),
            Switch(
              value: q.aiEvaluated ?? false,
              onChanged: (val) {
                setState(() {
                  questions[idx] = QuestionModel(
                    type: 'subjective',
                    question: q.question,
                    expectedAnswer: q.expectedAnswer,
                    aiEvaluated: val,
                  );
                });
              },
            )
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Questions'), backgroundColor: mainColor),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: questions.length,
        itemBuilder: (context, idx) {
          final q = questions[idx];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(
                  children: [
                    Expanded(child: TextFormField(
                      initialValue: q.question,
                      decoration: InputDecoration(labelText: "Question ${idx+1}"),
                      onChanged: (v) => questions[idx] = QuestionModel(
                        type: q.type,
                        question: v,
                        options: q.options,
                        answer: q.answer,
                        expectedAnswer: q.expectedAnswer,
                        aiEvaluated: q.aiEvaluated,
                      ),
                    )),
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      onPressed: () {
                        setState(() => questions.removeAt(idx));
                      },
                    )
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: q.type,
                  items: const [
                    DropdownMenuItem(value: 'objective', child: Text('Objective')),
                    DropdownMenuItem(value: 'subjective', child: Text('Subjective')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      if (v == null) return;
                      if (v == 'objective') {
                        questions[idx] = QuestionModel(
                          type: 'objective',
                          question: q.question,
                          options: q.options ?? ['',''],
                          answer: q.answer ?? 0,
                        );
                      } else {
                        questions[idx] = QuestionModel(
                          type: 'subjective',
                          question: q.question,
                          expectedAnswer: q.expectedAnswer ?? '',
                          aiEvaluated: q.aiEvaluated ?? false,
                        );
                      }
                    });
                  },
                ),
                const SizedBox(height: 8),
                if (q.type == 'objective') _buildObjectiveEditor(idx),
                if (q.type == 'subjective') _buildSubjectiveEditor(idx),
              ]),
            ),
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10, right: 10),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          FloatingActionButton(
            heroTag: 'addQuestion',
            onPressed: _addQuestion,
            backgroundColor: mainColor,
            child: const Icon(Icons.add),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: 'saveQuestions',
            onPressed: _saveQuestions,
            backgroundColor: Colors.green,
            child: const Icon(Icons.save),
          ),
        ]),
      ),
    );
  }
}
