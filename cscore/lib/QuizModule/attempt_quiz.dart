import 'package:flutter/material.dart';
import 'score_quiz.dart';

class AttemptQuizPage extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> questions;

  const AttemptQuizPage({super.key, required this.title, required this.questions});

  @override
  State<AttemptQuizPage> createState() => _AttemptQuizPageState();
}

class _AttemptQuizPageState extends State<AttemptQuizPage> {
  int currentQuestion = 0;
  List<int?> selectedAnswers = [];
  int score = 0;
  bool showAnswers = false;

  @override
  void initState() {
    super.initState();
    selectedAnswers = List<int?>.filled(widget.questions.length, null);
  }

  void nextQuestion() {
    if (currentQuestion < widget.questions.length - 1) {
      setState(() => currentQuestion++);
    } else {
      submitQuiz();
    }
  }

  void submitQuiz() async {
    int tempScore = 0;
    for (int i = 0; i < widget.questions.length; i++) {
      if (selectedAnswers[i] == widget.questions[i]['answer']) {
        tempScore++;
      }
    }

    setState(() {
      showAnswers = true;
      score = tempScore;
    });

    // Wait briefly to show visual feedback before navigating
    await Future.delayed(const Duration(seconds: 1));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ScoreQuizPage(
          title: widget.title,
          score: score,
          total: widget.questions.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[currentQuestion];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.title} (${currentQuestion + 1}/${widget.questions.length})',
        ),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question text
            Text(
              question['question'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Answer options
            ...List.generate(question['options'].length, (index) {
              final isSelected = selectedAnswers[currentQuestion] == index;
              final isCorrect = question['answer'] == index;
              final showColor = showAnswers
                  ? (isCorrect
                      ? Colors.green.withOpacity(0.2)
                      : isSelected
                          ? Colors.red.withOpacity(0.2)
                          : null)
                  : (isSelected ? Colors.green.withOpacity(0.1) : null);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: showColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? Colors.green
                        : Colors.grey.withOpacity(0.4),
                  ),
                ),
                child: RadioListTile<int>(
                  title: Text(
                    question['options'][index],
                    style: TextStyle(
                      fontSize: 16,
                      color: showAnswers
                          ? (isCorrect
                              ? Colors.green[800]
                              : isSelected
                                  ? Colors.red[800]
                                  : Colors.black)
                          : Colors.black,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  value: index,
                  groupValue: selectedAnswers[currentQuestion],
                  onChanged: showAnswers
                      ? null
                      : (int? value) {
                          setState(() {
                            selectedAnswers[currentQuestion] = value;
                          });
                        },
                  activeColor: Colors.green,
                  secondary: showAnswers
                      ? Icon(
                          isCorrect
                              ? Icons.check_circle
                              : isSelected
                                  ? Icons.cancel
                                  : null,
                          color: isCorrect
                              ? Colors.green
                              : isSelected
                                  ? Colors.red
                                  : Colors.transparent,
                        )
                      : null,
                ),
              );
            }),

            const Spacer(),

            // Next / Submit Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: selectedAnswers[currentQuestion] == null
                  ? null
                  : nextQuestion,
              child: Text(
                currentQuestion == widget.questions.length - 1
                    ? "Submit Quiz"
                    : "Next",
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
