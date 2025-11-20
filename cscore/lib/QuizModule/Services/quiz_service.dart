// lib/QuizModule/Services/quiz_service.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Models/quiz_model.dart';

class QuizService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<String> availableImages = [
    'assets/quiz_assets/html.jpg',
    'assets/quiz_assets/css.jpg',
    'assets/quiz_assets/javascript.jpg',
  ];

  /// Create quiz metadata document (returns doc id)
  Future<String?> createQuizMetadata({
    required String title,
    required String description,
    required String category,
    required String quizType,
    required int duration,
    required DateTime deadline,
    required int numQuestions,
    required int maxAttempts,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      String randomImage =
          availableImages[Random().nextInt(availableImages.length)];

      // 🔹 Save Quiz in "quiz" collection
      final ref = await _db.collection('quiz').add({
        'title': title,
        'description': description,
        'category': category,
        'quizType': quizType,
        'duration': duration,
        'deadline': Timestamp.fromDate(deadline),
        'numQuestions': numQuestions,
        'image': randomImage,
        'createdBy': user.uid,
        'createdAt': Timestamp.now(),
        'questions': [],
        'maxAttempts': maxAttempts,
      });

      // 🆕 ALSO create activity for dashboard
      await _db.collection('activities').add({
        'title': title,
        'description': description,
        'deadline': Timestamp.fromDate(deadline),
        'createdAt': Timestamp.now(),
        'type': 'Quiz',
        'createdBy': user.uid,
        'quizId': ref.id, // 🔗 Linked Quiz ID
        'isActive': true,
      });

      return ref.id;
    } catch (e) {
      print("❌ createQuizMetadata error: $e");
      return null;
    }
  }

  /// Add/replace entire questions array
  Future<bool> addQuestionsToQuiz(
      String quizId, List<QuestionModel> questions) async {
    try {
      await _db.collection('quiz').doc(quizId).update({
        'questions': questions.map((q) => q.toMap()).toList(),
        'numQuestions': questions.length,
      });
      return true;
    } catch (e) {
      print("❌ addQuestionsToQuiz error: $e");
      return false;
    }
  }

  /// Fetch all quizzes (student side)
  Stream<List<QuizModel>> fetchAllQuizzes() {
    return _db.collection('quiz').snapshots().map((snap) =>
        snap.docs.map((d) => QuizModel.fromDocument(d)).toList());
  }

  /// Fetch quizzes created by current teacher
  Stream<List<QuizModel>> fetchTeacherQuizzes() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('quiz')
        .where('createdBy', isEqualTo: user.uid)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => QuizModel.fromDocument(d)).toList());
  }

  /// Fetch single quiz by id
  Future<QuizModel?> fetchQuizById(String quizId) async {
    try {
      final doc = await _db.collection('quiz').doc(quizId).get();
      if (!doc.exists) return null;
      return QuizModel.fromDocument(doc);
    } catch (e) {
      print("❌ fetchQuizById error: $e");
      return null;
    }
  }

  /// Update partial fields of quiz document
  Future<bool> updateQuiz(String quizId, Map<String, dynamic> updated) async {
    try {
      await _db.collection('quiz').doc(quizId).update(updated);
      return true;
    } catch (e) {
      print("❌ updateQuiz error: $e");
      return false;
    }
  }

  /// Delete quiz
  Future<bool> deleteQuiz(String quizId) async {
    try {
      await _db.collection('quiz').doc(quizId).delete();
      return true;
    } catch (e) {
      print("❌ deleteQuiz error: $e");
      return false;
    }
  }

  /// Mark specific question as evaluated by AI (subjective)
  Future<void> markQuestionEvaluated(
      String quizId, int questionIndex, bool isCorrect) async {
    try {
      final doc = await _db.collection('quiz').doc(quizId).get();
      if (!doc.exists) return;
      final data = doc.data()!;
      final questions =
          List<Map<String, dynamic>>.from(data['questions'] ?? []);
      if (questionIndex < 0 || questionIndex >= questions.length) return;
      questions[questionIndex]['aiEvaluated'] = isCorrect;
      await _db.collection('quiz').doc(quizId).update({'questions': questions});
    } catch (e) {
      print("❌ markQuestionEvaluated error: $e");
    }
  }
}
