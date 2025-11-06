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
        'questions': [], // will be filled later
      });

      return quizRef.id;
    } catch (e) {
      print("❌ Error creating quiz metadata: $e");
      return null;
    }
  }

  /// ✅ Add questions (supports expectedAnswer)
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

  /// ✅ Fetch all quizzes (student side)
  Stream<List<QuizModel>> fetchAllQuizzes() {
    return _db.collection('quizzes').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => QuizModel.fromDocument(doc)).toList();
    });
  }

  /// ✅ Fetch quizzes created by the current teacher
  Stream<List<QuizModel>> fetchTeacherQuizzes() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('quizzes')
        .where('createdBy', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => QuizModel.fromDocument(doc)).toList());
  }

  /// ✅ Fetch single quiz
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

  /// ✅ Delete a quiz
  Future<bool> deleteQuiz(String quizId) async {
    try {
      await _db.collection('quizzes').doc(quizId).delete();
      return true;
    } catch (e) {
      print("❌ Error deleting quiz: $e");
      return false;
    }
  }

  /// ✅ Update quiz (future sprint)
  Future<bool> updateQuiz(String quizId, Map<String, dynamic> updated) async {
    try {
      await _db.collection('quizzes').doc(quizId).update(updated);
      return true;
    } catch (e) {
      print("❌ Error updating quiz: $e");
      return false;
    }
  }
}
