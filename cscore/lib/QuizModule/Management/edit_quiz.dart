// lib/QuizModule/Management/edit_quiz.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- ADDED
import 'package:cscore/QuizModule/Services/quiz_service.dart';
import 'package:cscore/QuizModule/Models/quiz_model.dart';
import 'edit_question_page.dart';

const Color mainColor = Color.fromRGBO(0, 70, 67, 1);

class EditQuizPage extends StatefulWidget {
  final String quizId;
  const EditQuizPage({super.key, required this.quizId});

  @override
  State<EditQuizPage> createState() => _EditQuizPageState();
}

class _EditQuizPageState extends State<EditQuizPage> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  QuizModel? _quiz;

  // editable fields
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _categoryController;
  String _quizType = 'exercise';
  int _duration = 10;
  int _numQuestions = 1;
  int _maxAttempts = 1;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descController = TextEditingController();
    _categoryController = TextEditingController();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    final quiz = await QuizService().fetchQuizById(widget.quizId);
    if (quiz == null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Quiz not found.")));
        Navigator.pop(context);
      }
      return;
    }
    setState(() {
      _quiz = quiz;
      _titleController.text = quiz.title;
      _descController.text = quiz.description;
      _categoryController.text = quiz.category;
      _quizType = quiz.quizType;
      _duration = quiz.duration;
      _numQuestions = quiz.numQuestions;
      _maxAttempts = quiz.maxAttempts;
      _deadline = quiz.deadline;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _saveMetadata() async {
    if (!_formKey.currentState!.validate()) return;

    // build update map
    final Map<String, dynamic> updated = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'category': _categoryController.text.trim(),
      'quizType': _quizType,
      'duration': _duration,
      'numQuestions': _numQuestions,
      'maxAttempts': _maxAttempts,
    };

    if (_deadline != null) {
      updated['deadline'] = Timestamp.fromDate(_deadline!); // uses imported Timestamp
    }

    final success = await QuizService().updateQuiz(widget.quizId, updated);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Quiz updated.")));
        // reload to reflect changes
        await _loadQuiz();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Failed to update quiz.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Quiz"), backgroundColor: mainColor),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Title"),
                validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 3,
                validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: "Category"),
                validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _quizType,
                decoration: const InputDecoration(labelText: "Quiz Type"),
                items: const [
                  DropdownMenuItem(value: "exercise", child: Text("Exercise")),
                  DropdownMenuItem(value: "exam", child: Text("Exam")),
                ],
                onChanged: (v) => setState(() => _quizType = v ?? 'exercise'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _duration.toString(),
                decoration: const InputDecoration(labelText: "Duration (minutes)"),
                keyboardType: TextInputType.number,
                onChanged: (v) => _duration = int.tryParse(v) ?? _duration,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _numQuestions.toString(),
                decoration: const InputDecoration(labelText: "Number of Questions"),
                keyboardType: TextInputType.number,
                onChanged: (v) => _numQuestions = int.tryParse(v) ?? _numQuestions,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _maxAttempts.toString(),
                decoration: const InputDecoration(labelText: "Max Attempts"),
                keyboardType: TextInputType.number,
                onChanged: (v) => _maxAttempts = int.tryParse(v) ?? _maxAttempts,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(_deadline == null
                        ? "Deadline: not set"
                        : "Deadline: ${DateFormat('dd/MM/yyyy').format(_deadline!)}"),
                  ),
                  TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate:
                              _deadline ?? DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _deadline = picked);
                      },
                      child: const Text("Select"))
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: mainColor),
                      onPressed: _saveMetadata,
                      child: const Text("Save Metadata"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      onPressed: () {
                        // open question editor
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditQuestionPage(
                              quizId: widget.quizId,
                              initialQuestions: _quiz!.questions,
                            ),
                          ),
                        ).then((v) => _loadQuiz()); // reload when return
                      },
                      child: const Text("Edit Questions"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
