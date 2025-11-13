// attempt_quiz.dart (patched)
// - fixes Submit button not enabling by adding a controller listener
// - makes updateProgress() resilient and safe
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cscore/QuizModule/Models/quiz_model.dart';
import 'score_quiz.dart';
import 'package:cscore/QuizModule/Data/quiz_data.dart';

const Color mainColor = Color.fromRGBO(0, 70, 67, 1);

class AttemptQuizPage extends StatefulWidget {
  final QuizModel quiz;

  const AttemptQuizPage({super.key, required this.quiz});

  @override
  State<AttemptQuizPage> createState() => _AttemptQuizPageState();
}

class _AttemptQuizPageState extends State<AttemptQuizPage> {
  int currentQuestion = 0;
  int score = 0;
  List<dynamic> answers = [];

  bool showFeedback = false;
  bool isLocked = false;

  late Timer countdown;
  int remainingSeconds = 0;

  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // prepare answers placeholder
    answers = List<dynamic>.filled(widget.quiz.questions.length, null);

    // timer
    remainingSeconds = widget.quiz.duration * 60;
    startTimer();

    // IMPORTANT: listen to controller so UI rebuilds when user types
    _textController.addListener(() {
      // only rebuild if widget still mounted
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    countdown.cancel();
    _textController.removeListener(() { });
    _textController.dispose();
    super.dispose();
  }

  // ------------------ TIMER ------------------
  void startTimer() {
    countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (remainingSeconds <= 0) {
        submitQuiz(autoSubmit: true);
        timer.cancel();
      } else {
        setState(() => remainingSeconds--);
      }
    });
  }

  String formatTime(int sec) {
    int m = sec ~/ 60;
    int s = sec % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  // ------------------ OBJECTIVE ANSWER HANDLER ------------------
  Future<void> handleAnswerTap(int index) async {
    if (isLocked) return;

    setState(() {
      answers[currentQuestion] = index;
      showFeedback = true;
      isLocked = true;
    });

    final question = widget.quiz.questions[currentQuestion];
    final correctIndex = question.answer ?? -1;

    final feedback = evaluateQuizAnswers(
      [
        {
          'type': 'objective',
          'question': question.question,
          'options': question.options,
          'answer': correctIndex,
        }
      ],
      {0: index},
    ).first;

    if (feedback['correct'] == true) score++;

    // show feedback dialog
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(
          feedback['correct'] ? '✅ Correct!' : '❌ Incorrect',
          style: TextStyle(
            color: feedback['correct'] ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(feedback['message']),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Next"),
          )
        ],
      ),
    );

    if (!mounted) return;
    nextQuestion();
  }

  // ------------------ SUBJECTIVE HANDLER (uses controller) ------------------
  Future<void> handleSubjectiveSubmit() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // store the student's text locally
    answers[currentQuestion] = text;

    final feedback = evaluateQuizAnswers(
      [
        {
          'type': 'subjective',
          'question': widget.quiz.questions[currentQuestion].question,
        }
      ],
      {0: text},
    ).first;

    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(
          feedback['correct'] ? '✅ Good!' : '💬 Feedback',
          style: TextStyle(
            color: feedback['correct'] ? Colors.green : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(feedback['message']),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Next"),
          )
        ],
      ),
    );

    if (!mounted) return;
    // optionally increment score if feedback indicates correct for subjective
    if (feedback['correct'] == true) score++;

    nextQuestion();
  }

  // ------------------ NEXT QUESTION ------------------
  void nextQuestion() {
    if (!mounted) return;

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

  // ------------------ PROGRESS SAVING ------------------
  Future<void> updateProgress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final progressRef = FirebaseFirestore.instance
          .collection('progress')
          .doc(user.uid)
          .collection('quizProgress')
          .doc(widget.quiz.id);

      final snapshot = await progressRef.get();

      int oldHighest = 0;
      int attempts = 0;
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        oldHighest = (data['highestScore'] is num) ? (data['highestScore'] as num).toInt() : 0;
        attempts = (data['attemptCount'] is num) ? (data['attemptCount'] as num).toInt() : 0;
      }

      await progressRef.set({
        'attemptCount': attempts + 1,
        'currentScore': score,
        'highestScore': score > oldHighest ? score : oldHighest,
        'totalScore': widget.quiz.questions.length,
        'attemptDate': FieldValue.serverTimestamp(),
        'status': 'completed',
        'answers': answers,
      }, SetOptions(merge: true));
    } catch (e, st) {
      // Log and continue — don't crash UI
      // In development console you'll see the error
      debugPrint("❌ updateProgress error: $e\n$st");
    }
  }

  // ------------------ SUBMIT QUIZ ------------------
  void submitQuiz({bool autoSubmit = false}) async {
    try {
      countdown.cancel();
    } catch (_) {}

    // Save progress (fire-and-wait) — ensures DB updated before moving on
    await updateProgress();

    if (!mounted) return;

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

  // ------------------ UI ------------------
  @override
  Widget build(BuildContext context) {
    final question = widget.quiz.questions[currentQuestion];
    final isObjective = question.type == "objective";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildHeader(),
              const SizedBox(height: 20),
              Text(
                question.question,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (isObjective) ...buildObjective(question),
              if (!isObjective) ...buildSubjective(),
              const Spacer(),
              LinearProgressIndicator(
                value: (currentQuestion + 1) / widget.quiz.questions.length,
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

  Widget buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.quiz.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: mainColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
          child: Text(formatTime(remainingSeconds),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        ),
      ],
    );
  }

  List<Widget> buildObjective(QuestionModel question) {
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
          border: Border.all(color: isSelected ? mainColor : Colors.grey.withOpacity(0.4)),
        ),
        child: RadioListTile<int>(
          title: Text(question.options![index]),
          value: index,
          groupValue: answers[currentQuestion],
          activeColor: mainColor,
          onChanged: (_) => handleAnswerTap(index),
        ),
      );
    });
  }

  List<Widget> buildSubjective() {
    final isLast = currentQuestion == widget.quiz.questions.length - 1;
    return [
      const Text("Your Answer:", style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      TextField(
        controller: _textController,
        maxLines: 6,
        decoration: InputDecoration(hintText: "Type your answer...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        onChanged: (v) {
          // we already update answers with the controller, but keep this for redundancy
          answers[currentQuestion] = v;
          // no setState needed here because controller listener will rebuild
        },
      ),
      const SizedBox(height: 20),
      Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _textController.text.isNotEmpty ? mainColor : Colors.grey,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _textController.text.isNotEmpty ? () => handleSubjectiveSubmit() : null,
          child: Text(isLast ? "Submit Quiz" : "Next Question", style: const TextStyle(color: Colors.white)),
        ),
      ),
    ];
  }
}
