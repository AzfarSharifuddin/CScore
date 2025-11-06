import 'dart:async';
import 'package:flutter/material.dart';
import 'score_quiz.dart';

const mainColor = Color.fromRGBO(0, 70, 67, 1);

class AttemptQuizPage extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> questions;
  final int duration; // ✅ minutes
  final DateTime deadline; // ✅ DateTime

  const AttemptQuizPage({
    super.key,
    required this.title,
    required this.questions,
    required this.duration,
    required this.deadline,
  });

  @override
  State<AttemptQuizPage> createState() => _AttemptQuizPageState();
}

class _AttemptQuizPageState extends State<AttemptQuizPage> {
  int currentQuestion = 0;
  List<dynamic> answers = [];
  int score = 0;
  bool showFeedback = false;
  bool isLocked = false;

  final TextEditingController _textController = TextEditingController();

  // ✅ Countdown timer
  late int remainingSeconds;
  Timer? timer;

  @override
  void initState() {
    super.initState();

    // ✅ duration in minutes → seconds
    remainingSeconds = widget.duration * 60;

    startTimer();

    answers = List<dynamic>.filled(widget.questions.length, null);
  }

  // ✅ Timer with auto-submit when time ends
  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;

      setState(() {
        remainingSeconds--;
      });

      if (remainingSeconds <= 0) {
        timer?.cancel();
        submitQuiz(); // AUTO-SUBMIT
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return "$mins:${secs.toString().padLeft(2, '0')}";
  }

  Future<void> handleAnswerTap(int index) async {
    if (isLocked) return;

    setState(() {
      answers[currentQuestion] = index;
      showFeedback = true;
      isLocked = true;
    });

    if (index == widget.questions[currentQuestion]['answer']) {
      score++;
    }

    await Future.delayed(const Duration(milliseconds: 1200));

    nextQuestion();
  }

  void nextQuestion() {
    if (currentQuestion < widget.questions.length - 1) {
      setState(() {
        currentQuestion++;
        _textController.clear();
        showFeedback = false;
        isLocked = false;
      });
    } else {
      submitQuiz();
    }
  }

  void submitQuiz() {
    timer?.cancel();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ScoreQuizPage(
          title: widget.title,
          score: score,
          total: widget.questions.length,
          subjectiveAnswers: getSubjectiveAnswers(),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> getSubjectiveAnswers() {
    final list = <Map<String, dynamic>>[];

    for (int i = 0; i < widget.questions.length; i++) {
      if (widget.questions[i]['type'] == 'subjective') {
        list.add({
          'question': widget.questions[i]['question'],
          'answer': answers[i] ?? '',
        });
      }
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[currentQuestion];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 20),

              Text(
                question['question'],
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              if (question['type'] == 'objective') ..._buildObjectiveOptions(question),
              if (question['type'] == 'subjective') ..._buildSubjectiveInput(),

              const Spacer(),

              LinearProgressIndicator(
                value: (currentQuestion + 1) / widget.questions.length,
                backgroundColor: Colors.grey[300],
                color: mainColor,
                minHeight: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ✅ Title
        Flexible(
          child: Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: mainColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // ✅ Timer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            formatTime(remainingSeconds),
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildObjectiveOptions(Map<String, dynamic> question) {
    return List.generate(question['options'].length, (index) {
      final isSelected = answers[currentQuestion] == index;
      final isCorrect = question['answer'] == index;

      Color? bgColor;
      if (showFeedback) {
        if (isCorrect) bgColor = Colors.green.withOpacity(0.2);
        else if (isSelected) bgColor = Colors.red.withOpacity(0.2);
      } else if (isSelected) {
        bgColor = Colors.green.withOpacity(0.1);
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.withOpacity(0.4),
          ),
        ),
        child: RadioListTile<int>(
          title: Text(question['options'][index]),
          value: index,
          groupValue: answers[currentQuestion],
          onChanged: (_) => handleAnswerTap(index),
          activeColor: Colors.green,
        ),
      );
    });
  }

  List<Widget> _buildSubjectiveInput() {
    return [
      const Text(
        "Your Answer:",
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      const SizedBox(height: 10),

      TextField(
        controller: _textController,
        decoration: InputDecoration(
          hintText: "Type your answer here...",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        maxLines: 4,
        onChanged: (v) {
          answers[currentQuestion] = v;
          setState(() {});
        },
      ),

      const SizedBox(height: 20),

      Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _textController.text.isNotEmpty ? mainColor : Colors.grey,
          ),
          onPressed: _textController.text.isNotEmpty ? nextQuestion : null,
          child: Text(
            currentQuestion == widget.questions.length - 1
                ? "Submit Quiz"
                : "Next Question",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    ];
  }
}
