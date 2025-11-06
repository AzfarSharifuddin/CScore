import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cscore/QuizModule/Models/quiz_model.dart';
import 'score_quiz.dart';
import 'package:cscore/QuizModule/Data/quiz_data.dart'; // or the correct path where evaluateQuizAnswers() lives


const Color mainColor = Color.fromRGBO(0, 70, 67, 1);

class AttemptQuizPage extends StatefulWidget {
  final QuizModel quiz;

  const AttemptQuizPage({super.key, required this.quiz});

  @override
  State<AttemptQuizPage> createState() => _AttemptQuizPageState();
}

class _AttemptQuizPageState extends State<AttemptQuizPage> {
  int currentQuestion = 0;
  List<dynamic> answers = [];
  int score = 0;
  bool showFeedback = false;
  bool isLocked = false;

  late Timer countdown;
  int remainingSeconds = 0;

  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Prepare answer placeholders
    answers = List<dynamic>.filled(widget.quiz.questions.length, null);

    // Setup duration as seconds
    remainingSeconds = widget.quiz.duration * 60;

    // Start countdown timer
    startTimer();
  }

  @override
  void dispose() {
    countdown.cancel();
    _textController.dispose();
    super.dispose();
  }

  // ✅ Countdown Timer
  void startTimer() {
    countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds <= 0) {
        submitQuiz(autoSubmit: true);
        timer.cancel();
      } else {
        setState(() {
          remainingSeconds--;
        });
      }
    });
  }

  String formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  // ✅ Handle objective answer tap
Future<void> handleAnswerTap(int index) async {
  if (isLocked) return;

  setState(() {
    answers[currentQuestion] = index;
    showFeedback = true;
    isLocked = true;
  });

  final question = widget.quiz.questions[currentQuestion];
  final correctIndex = question.answer ?? -1;

  // Use the fake AI evaluator for feedback
  final feedback = evaluateQuizAnswers(
    [ // just one question to evaluate
      {
        'type': 'objective',
        'question': question.question,
        'options': question.options,
        'answer': correctIndex,
      }
    ],
    {0: index},
  ).first;

  // Increase score if correct
  if (feedback['correct'] == true) score++;

  // Show popup with feedback message
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(
        feedback['correct'] ? '✅ Correct!' : '❌ Incorrect',
        style: TextStyle(
          color: feedback['correct'] ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        feedback['message'],
        style: const TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Next'),
        )
      ],
    ),
  );

  // Move to next question after closing dialog
  nextQuestion();
}

  void nextQuestion() {
    if (currentQuestion < widget.quiz.questions.length - 1) {
      setState(() {
        currentQuestion++;
        showFeedback = false;
        isLocked = false;
        _textController.clear();
      });
    } else {
      submitQuiz();
    }
  }

  // ✅ Submit quiz
  void submitQuiz({bool autoSubmit = false}) {
    countdown.cancel();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ScoreQuizPage(
          quiz: widget.quiz,
          score: score,
          total: widget.quiz.questions.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.quiz.questions[currentQuestion];
    final isObjective = question.type == "objective";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Padding(
            key: ValueKey(currentQuestion),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Header: Title + Timer
                _buildHeader(),

                const SizedBox(height: 20),
                Text(
                  question.question,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                if (isObjective) ..._buildObjective(question),
                if (!isObjective) ..._buildSubjective(),

                const Spacer(),

                // ✅ Progress bar
                LinearProgressIndicator(
                  value: (currentQuestion + 1) / widget.quiz.questions.length,
                  backgroundColor: Colors.grey[300],
                  color: mainColor,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.quiz.title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: mainColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // ✅ Timer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            formatTime(remainingSeconds),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  // ✅ Objective Question UI
  List<Widget> _buildObjective(QuestionModel question) {
    return List.generate(question.options!.length, (index) {
      final isSelected = answers[currentQuestion] == index;
      final isCorrect = question.answer == index;

      Color? bg;
      if (showFeedback) {
        if (isCorrect) bg = Colors.green.withOpacity(0.25);
        else if (isSelected) bg = Colors.red.withOpacity(0.25);
      } else if (isSelected) {
        bg = mainColor.withOpacity(0.15);
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? mainColor : Colors.grey.withOpacity(0.4),
          ),
        ),
        child: RadioListTile<int>(
          title: Text(
            question.options![index],
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          value: index,
          groupValue: answers[currentQuestion],
          activeColor: mainColor,
          onChanged: (_) => handleAnswerTap(index),
        ),
      );
    });
  }

  // ✅ Subjective Question UI
  List<Widget> _buildSubjective() {
    return [
      const Text("Your Answer:",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      const SizedBox(height: 10),
      TextField(
        controller: _textController,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: "Type your answer here...",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (val) => answers[currentQuestion] = val,
      ),
      const SizedBox(height: 20),

      Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _textController.text.isNotEmpty
                ? mainColor
                : Colors.grey,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _textController.text.isNotEmpty
    ? () async {
        final userText = _textController.text.trim();

        // Fake AI feedback for subjective
        final feedback = evaluateQuizAnswers(
          [
            {
              'type': 'subjective',
              'question': widget.quiz.questions[currentQuestion].question,
            }
          ],
          {0: userText},
        ).first;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(
              feedback['correct'] ? '✅ Looks Good!' : '💬 Feedback',
              style: TextStyle(
                color: feedback['correct'] ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              feedback['message'],
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Next'),
              ),
            ],
          ),
        );

        nextQuestion();
      }
    : null,

          child: Text(
            currentQuestion == widget.quiz.questions.length - 1
                ? "Submit Quiz"
                : "Next Question",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    ];
  }
}
