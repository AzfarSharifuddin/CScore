import 'package:flutter/material.dart';
import 'score_quiz.dart';

class AttemptQuizPage extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> questions;

  const AttemptQuizPage({
    super.key,
    required this.title,
    required this.questions,
  });

  @override
  State<AttemptQuizPage> createState() => _AttemptQuizPageState();
}

class _AttemptQuizPageState extends State<AttemptQuizPage> {
  int currentQuestion = 0;
  List<int?> selectedAnswers = [];
  int score = 0;
  bool showAnswers = false;
  bool isLocked = false;

  @override
  void initState() {
    super.initState();
    selectedAnswers = List<int?>.filled(widget.questions.length, null);
  }

  Future<void> handleAnswerTap(int index) async {
    if (isLocked) return; // Prevent double taps
    setState(() {
      selectedAnswers[currentQuestion] = index;
      showAnswers = true;
      isLocked = true;
    });

    // Calculate partial score for this question
    if (index == widget.questions[currentQuestion]['answer']) {
      score++;
    }

    // Wait 1.2s to show visual feedback before moving on
    await Future.delayed(const Duration(milliseconds: 1200));

    if (currentQuestion < widget.questions.length - 1) {
      setState(() {
        currentQuestion++;
        showAnswers = false;
        isLocked = false;
      });
    } else {
      // Go to result page
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
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[currentQuestion];

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} (${currentQuestion + 1}/${widget.questions.length})'),
        backgroundColor: Colors.green,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Padding(
          key: ValueKey(currentQuestion),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question['question'],
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Options
              ...List.generate(question['options'].length, (index) {
                final isSelected = selectedAnswers[currentQuestion] == index;
                final isCorrect = question['answer'] == index;

                // Determine visual feedback color
                Color? bgColor;
                if (showAnswers) {
                  if (isCorrect) bgColor = Colors.green.withOpacity(0.2);
                  else if (isSelected) bgColor = Colors.red.withOpacity(0.2);
                } else if (isSelected) {
                  bgColor = Colors.green.withOpacity(0.1);
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: bgColor,
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
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    value: index,
                    groupValue: selectedAnswers[currentQuestion],
                    onChanged: (int? value) => handleAnswerTap(index),
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

              // Progress Indicator
              Center(
                child: Text(
                  "Question ${currentQuestion + 1} of ${widget.questions.length}",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (currentQuestion + 1) / widget.questions.length,
                backgroundColor: Colors.grey[300],
                color: Colors.green,
                minHeight: 6,
                borderRadius: BorderRadius.circular(10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
