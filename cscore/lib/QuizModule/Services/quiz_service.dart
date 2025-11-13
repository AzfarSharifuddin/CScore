// quiz_service.dart
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

  Future<String?> createQuizMetadata({
    required String title,
    required String description,
    required String category,
    required String quizType,
    required int duration,
    required DateTime deadline,
    required int numQuestions,
    required int maxAttempts, // new
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      String randomImage = availableImages[Random().nextInt(availableImages.length)];

      final quizRef = await _db.collection('quiz').add({
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

      return quizRef.id;
    } catch (e) {
      print("❌ Error creating quiz metadata: $e");
      return null;
    }
  }

  Future<bool> addQuestionsToQuiz(String quizId, List<QuestionModel> questions) async {
    try {
      await _db.collection('quiz').doc(quizId).update({
        'questions': questions.map((q) => q.toMap()).toList(),
        'numQuestions': questions.length,
      });
      return true;
    } catch (e) {
      print("❌ Error adding questions: $e");
      return false;
    }
  }

  Stream<List<QuizModel>> fetchAllQuizzes() {
    return _db.collection('quiz').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => QuizModel.fromDocument(doc)).toList();
    });
  }

  Stream<List<QuizModel>> fetchTeacherQuizzes() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('quiz')
        .where('createdBy', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => QuizModel.fromDocument(d)).toList());
  }

  Future<QuizModel?> fetchQuizById(String quizId) async {
    try {
      final doc = await _db.collection('quiz').doc(quizId).get();
      if (!doc.exists) return null;
      return QuizModel.fromDocument(doc);
    } catch (e) {
      print("❌ Error fetching quiz: $e");
      return null;
    }
  }

  Future<bool> updateQuiz(String quizId, Map<String, dynamic> updated) async {
    try {
      await _db.collection('quiz').doc(quizId).update(updated);
      return true;
    } catch (e) {
      print("❌ Error updating quiz: $e");
      return false;
    }
  }

  Future<bool> deleteQuiz(String quizId) async {
    try {
      await _db.collection('quiz').doc(quizId).delete();
      return true;
    } catch (e) {
      print("❌ Error deleting quiz: $e");
      return false;
    }
  }

  Future<void> markQuestionEvaluated(String quizId, int questionIndex, bool isCorrect) async {
    try {
      final doc = await _db.collection('quiz').doc(quizId).get();
      if (!doc.exists) return;
      final data = doc.data()!;
      final questions = List<Map<String, dynamic>>.from(data['questions'] ?? []);
      if (questionIndex < 0 || questionIndex >= questions.length) return;
      questions[questionIndex]['aiEvaluated'] = isCorrect;
      await _db.collection('quiz').doc(quizId).update({'questions': questions});
    } catch (e) {
      print("❌ Error updating AI evaluation: $e");
    }
  }
}
