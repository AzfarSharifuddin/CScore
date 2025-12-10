// lib/QuizModule/Student/review_attempt_page.dart
//
// Student read-only review page.
// Uses the same visual structure as the teacher's ViewAttemptDetailsPage,
// but removes all editing / saving logic and just shows:
//   - question
//   - student answer / selected option
//   - AI explanation / feedback
//
// Requires: QuizModel, QuizService, Firebase Auth/Firestore.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:cscore/QuizModule/Models/quiz_model.dart';
import 'package:cscore/QuizModule/Services/quiz_service.dart';

const Color mainColor = Color.fromRGBO(0, 70, 67, 1);

class StudentReviewAttemptPage extends StatelessWidget {
  final String quizId;
  final String quizTitle;

  const StudentReviewAttemptPage({
    super.key,
    required this.quizId,
    required this.quizTitle,
  });

  // ---------- DATA FETCHING ----------

  Future<Map<String, dynamic>?> _fetchAttemptData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final progressRef = FirebaseFirestore.instance
        .collection('progress')
        .doc(user.uid)
        .collection('quizProgress')
        .doc(quizId);

    final snapshot = await progressRef.get();
    return snapshot.data();
  }

  Future<QuizModel> _fetchQuiz() async {
    final quiz = await QuizService().fetchQuizById(quizId);
    if (quiz == null) {
      throw Exception("Quiz with ID $quizId not found.");
    }
    return quiz;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Your Attempt",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: mainColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: Future.wait([_fetchAttemptData(), _fetchQuiz()]).then((results) {
          final attemptData = results[0] as Map<String, dynamic>?;
          final quizModel = results[1] as QuizModel;

          if (attemptData == null) {
            throw Exception("No attempt data found for this quiz.");
          }

          return {
            'quiz': quizModel,
            'answers': attemptData['answers'] as List<dynamic>? ?? [],
          };
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: mainColor),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text("Error loading attempt: ${snapshot.error}"),
            );
          }

          final quiz = snapshot.data!['quiz'] as QuizModel;
          final userAnswers = snapshot.data!['answers'] as List<dynamic>;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: quiz.questions.length,
            itemBuilder: (context, index) {
              final question = quiz.questions[index];
              final userAnswer =
                  userAnswers.length > index ? userAnswers[index] : null;

              return _buildQuestionCard(index, question, userAnswer);
            },
          );
        },
      ),
    );
  }

  // ---------- QUESTION CARD ----------

  Widget _buildQuestionCard(
    int index,
    QuestionModel question,
    dynamic userAnswer,
  ) {
    final isObjective = question.type == "objective";
    final isCorrect = isObjective
        ? (userAnswer is int && userAnswer == question.answer)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Question ${index + 1}: (${isObjective ? "Objective" : "Subjective"})",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: mainColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              question.question,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Divider(height: 25),

            if (isObjective)
              _buildObjectiveAnswer(question, userAnswer as int?, isCorrect),
            if (!isObjective)
              _buildSubjectiveAnswer(question, userAnswer as String?),
          ],
        ),
      ),
    );
  }

  // ---------- OBJECTIVE (MCQ) ANSWER SECTION ----------

  Widget _buildObjectiveAnswer(
    QuestionModel question,
    int? selectedIndex,
    bool? isCorrect,
  ) {
    final options = question.options ?? [];
    final selectedText = (selectedIndex != null &&
            selectedIndex >= 0 &&
            selectedIndex < options.length)
        ? options[selectedIndex]
        : "No answer selected";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(
          label: "Your Answer:",
          value: selectedText,
          color: isCorrect == true ? Colors.green.shade700 : Colors.red.shade700,
          icon: isCorrect == true ? Icons.check_circle : Icons.cancel,
          isAnswer: true,
        ),
        const SizedBox(height: 10),

        // AI Explanation from cache (read-only)
        FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('ai_generated_content')
              .doc(question.id)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text("Loading AI explanation...");
            }

            final data = snapshot.data?.data() as Map<String, dynamic>?;
            final rawExplanation =
                data?['ai_output_ms'] as String? ?? "No AI explanation found.";

            final prefix =
                isCorrect == true ? "✅ Betul! " : "❌ Salah. ";
            final message = prefix + rawExplanation;

            return _buildFeedbackBox(
              message: message,
              isCorrect: isCorrect,
            );
          },
        ),
      ],
    );
  }

  // ---------- SUBJECTIVE ANSWER SECTION ----------

  Widget _buildSubjectiveAnswer(
    QuestionModel question,
    String? userAnswer,
  ) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Text("You must be logged in to view this feedback.");
    }

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('ai_generated_content')
          .where('content_type', isEqualTo: 'SUBJECTIVE_GRADE')
          .where('related_question_id', isEqualTo: question.id)
          .where('related_user_id', isEqualTo: currentUser.uid)
          .orderBy('generated_on', descending: true)
          .limit(1)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading your answer and AI feedback...");
        }

        final doc = snapshot.data?.docs.isNotEmpty == true
            ? snapshot.data!.docs.first
            : null;
        final gradeData = doc?.data() as Map<String, dynamic>?;

        final gradeMessage =
            gradeData?['ai_output_ms'] as String? ??
                "No AI feedback available for this attempt.";
        final isGradedCorrect = gradeData?['grade_correct'] as bool?;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              label: "Your Answer:",
              value: userAnswer ?? "No answer submitted.",
              color: mainColor,
              icon: Icons.edit_note,
              isAnswer: true,
            ),
            const SizedBox(height: 10),
            _buildFeedbackBox(
              message: gradeMessage,
              isCorrect: isGradedCorrect,
            ),
          ],
        );
      },
    );
  }

  // ---------- SHARED UI HELPERS ----------

  Widget _buildFeedbackBox({
    required String message,
    required bool? isCorrect,
  }) {
    final Color boxColor = isCorrect == true
        ? Colors.green.withOpacity(0.15)
        : (isCorrect == false
            ? Colors.orange.withOpacity(0.15)
            : Colors.grey.shade50);

    final Color borderColor = isCorrect == true
        ? Colors.green
        : (isCorrect == false ? Colors.orange : mainColor);

    final TextStyle textStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: isCorrect == true
          ? Colors.green[900]
          : (isCorrect == false ? Colors.orange[900] : Colors.black87),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Text(message, style: textStyle),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    bool isAnswer = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isAnswer ? color.withOpacity(0.08) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: isAnswer ? Colors.black87 : color,
            ),
          ),
        ),
      ],
    );
  }
}
