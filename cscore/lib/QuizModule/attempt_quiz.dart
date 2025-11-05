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
  List<dynamic> answers = []; // can hold int? or String for subjective
  int score = 0;
  bool showFeedback = false;
  bool isLocked = false;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    answers = List<dynamic>.filled(widget.questions.length, null);
  }

  Future<void> handleAnswerTap(int index) async {
    if (isLocked) return;
    setState(() {
      answers[currentQuestion] = index;
      showFeedback = true;
      isLocked = true;
    });

    if (index == widget.questions[currentQuestion]['answer']) score++;

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
    final List<Map<String, dynamic>> subjective = [];
    for (int i = 0; i < widget.questions.length; i++) {
      if (widget.questions[i]['type'] == 'subjective') {
        subjective.add({
          'question': widget.questions[i]['question'],
          'answer': answers[i] ?? '',
        });
      }
    }
    return subjective;
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[currentQuestion];
    final questionType = question['type'];

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} (${currentQuestion + 1}/${widget.questions.length})'),
        backgroundColor: Colors.green,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
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

              if (questionType == 'objective') ..._buildObjectiveOptions(question),
              if (questionType == 'subjective') ..._buildSubjectiveInput(),

              const Spacer(),
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

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.withOpacity(0.4),
          ),
        ),
        child: RadioListTile<int>(
          title: Text(
            question['options'][index],
            style: TextStyle(
              fontSize: 16,
              color: showFeedback
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
          groupValue: answers[currentQuestion],
          onChanged: (int? value) => handleAnswerTap(index),
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
          contentPadding: const EdgeInsets.all(12),
        ),
        maxLines: 4,
        onChanged: (value) {
          answers[currentQuestion] = value;
        },
      ),
      const SizedBox(height: 20),
      Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _textController.text.isEmpty ? null : nextQuestion,
          child: Text(
            currentQuestion == widget.questions.length - 1
                ? "Submit Quiz"
                : "Next Question",
          ),
        ),
      ),
    ];
  }
}
