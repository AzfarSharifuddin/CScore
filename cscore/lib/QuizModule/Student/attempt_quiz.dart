import 'package:flutter/material.dart';
import 'score_quiz.dart';

const mainColor = Color.fromRGBO(0, 70, 67, 1);

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
  List<dynamic> answers = [];
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
                // 🔹 Custom header instead of AppBar
                _buildHeader(),

                const SizedBox(height: 20),
                Text(
                  question['question'],
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                if (questionType == 'objective')
                  ..._buildObjectiveOptions(question),
                if (questionType == 'subjective')
                  ..._buildSubjectiveInput(),

                const Spacer(),

                // 🔹 Progress bar
                LinearProgressIndicator(
                  value: (currentQuestion + 1) / widget.questions.length,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + Progress counter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                widget.title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: mainColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: mainColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "${currentQuestion + 1}/${widget.questions.length}",
                style: const TextStyle(
                    color: mainColor, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 🟩 Objective Question UI
  List<Widget> _buildObjectiveOptions(Map<String, dynamic> question) {
    return List.generate(question['options'].length, (index) {
      final isSelected = answers[currentQuestion] == index;
      final isCorrect = question['answer'] == index;

      Color? bgColor;
      if (showFeedback) {
        if (isCorrect) bgColor = mainColor.withOpacity(0.2);
        else if (isSelected) bgColor = Colors.red.withOpacity(0.2);
      } else if (isSelected) {
        bgColor = mainColor.withOpacity(0.1);
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? mainColor
                : Colors.grey.withOpacity(0.4),
          ),
        ),
        child: RadioListTile<int>(
          title: Text(
            question['options'][index],
            style: TextStyle(
              fontSize: 16,
              color: showFeedback
                  ? (isCorrect
                      ? mainColor
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
          activeColor: mainColor,
        ),
      );
    });
  }

  // ✍️ Subjective Question UI
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
          setState(() {
            answers[currentQuestion] = value;
          });
        },
      ),
      const SizedBox(height: 20),

      AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _textController.text.isNotEmpty ? 1.0 : 0.5,
        child: Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _textController.text.isNotEmpty
                  ? mainColor
                  : Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: _textController.text.isNotEmpty ? nextQuestion : null,
            child: Text(
              currentQuestion == widget.questions.length - 1
                  ? "Submit Quiz"
                  : "Next Question",
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
    ];
  }
}
