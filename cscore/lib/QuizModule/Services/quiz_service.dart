import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cscore/QuizModule/Models/quiz_model.dart';

class QuizService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ✅ Random image picker for new quizzes
  final List<String> availableImages = [
    'assets/quiz_assets/html.jpg',
    'assets/quiz_assets/css.jpg',
    'assets/quiz_assets/javascript.jpg',
  ];

  /// ✅ Create Quiz metadata (first step)
  Future<String?> createQuizMetadata({
    required String title,
    required String description,
    required String category,
    required String difficulty,
    required int duration,
    required DateTime deadline,
    required int numQuestions,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      String randomImage =
          availableImages[Random().nextInt(availableImages.length)];

      final quizRef = await _db.collection('quizzes').add({
        'title': title,
        'description': description,
        'category': category,
        'difficulty': difficulty,
        'duration': duration,
        'deadline': Timestamp.fromDate(deadline),
        'numQuestions': numQuestions,
        'image': randomImage,
        'createdBy': user.uid,
        'createdAt': Timestamp.now(),
        'status': 'Not Attempted',
        'questions': [], // added later
      });

      return quizRef.id;
    } catch (e) {
      print("❌ Error creating quiz metadata: $e");
      return null;
    }
  }

  /// ✅ Add questions to an existing quiz document
  Future<bool> addQuestionsToQuiz(
      String quizId, List<QuestionModel> questions) async {
    try {
      await _db.collection('quizzes').doc(quizId).update({
        'questions': questions.map((q) => q.toMap()).toList(),
      });
      return true;
    } catch (e) {
      print("❌ Error adding questions: $e");
      return false;
    }
  }

  /// ✅ Fetch ALL quizzes (Student Side)
  Stream<List<QuizModel>> fetchAllQuizzes() {
    return _db.collection('quizzes').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => QuizModel.fromDocument(doc)).toList();
    });
  }

  /// ✅ Fetch quizzes created by current teacher
  Stream<List<QuizModel>> fetchTeacherQuizzes() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('quizzes')
        .where('createdBy', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => QuizModel.fromDocument(doc)).toList();
    });
  }

  /// ✅ Fetch a single quiz by ID
  Future<QuizModel?> fetchQuizById(String quizId) async {
    try {
      final doc = await _db.collection('quizzes').doc(quizId).get();
      if (!doc.exists) return null;
      return QuizModel.fromDocument(doc);
    } catch (e) {
      print("❌ Error fetching quiz: $e");
      return null;
    }
  }

  /// ✅ Delete a quiz (for future sprint)
  Future<bool> deleteQuiz(String quizId) async {
    try {
      await _db.collection('quizzes').doc(quizId).delete();
      return true;
    } catch (e) {
      print("❌ Error deleting quiz: $e");
      return false;
    }
  }

  /// ✅ Update quiz metadata (future sprint)
  Future<bool> updateQuiz(String quizId, Map<String, dynamic> updated) async {
    try {
      await _db.collection('quizzes').doc(quizId).update(updated);
      return true;
    } catch (e) {
      print("❌ Error updating quiz: $e");
      return false;
    }
  }

  /// ✅ NEW: Mark question as evaluated by AI
  Future<void> markQuestionEvaluated(
      String quizId, int questionIndex, bool isCorrect) async {
    try {
      final doc = await _db.collection('quizzes').doc(quizId).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final List<Map<String, dynamic>> questions =
          List<Map<String, dynamic>>.from(data['questions']);

      // Update specific question
      questions[questionIndex]['aiEvaluated'] = isCorrect;

      await _db.collection('quizzes').doc(quizId).update({
        'questions': questions,
      });

      print("✅ Question ${questionIndex + 1} marked as ${isCorrect ? 'Correct' : 'Incorrect'} by AI.");
    } catch (e) {
      print("❌ Error updating AI evaluation: $e");
    }
  }
}
