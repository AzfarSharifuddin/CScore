import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:async/async.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cscore/ProgressTrackerModule/Model/progress_record.dart';

class ProgressService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Add manual progress
  Future<void> addProgress(String userId, ProgressRecord record) async {
    await _db
        .collection('progress')
        .doc(userId)
        .collection('records')
        .add(record.toMap());
  }

  /// Update manual progress
  Future<void> updateProgress(String userId, ProgressRecord record) async {
    await _db
        .collection('progress')
        .doc(userId)
        .collection('records')
        .doc(record.id)
        .update(record.toMap());
  }

  /// Delete manual progress
  Future<void> deleteProgress(String userId, String recordId) async {
    await _db
        .collection('progress')
        .doc(userId)
        .collection('records')
        .doc(recordId)
        .delete();
  }

  /// STREAM — Manual progress
  Stream<List<ProgressRecord>> getManualProgress(String userId) {
    return _db
        .collection('progress')
        .doc(userId)
        .collection('records')
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ProgressRecord.fromMap(d.data(), d.id))
            .toList());
  }

  /// STREAM — Quiz progress (Option A)
 Stream<List<ProgressRecord>> getQuizProgress(String userId) {
  return _db
      .collection('progress')
      .doc(userId)
      .collection('quizProgress')
      .snapshots()
      .asyncMap((snap) async {
    List<ProgressRecord> list = [];

    for (var doc in snap.docs) {
      final data = doc.data();
      final quizId = doc.id;  // <-- Your quiz ID

      // --- Fetch quiz info from /quiz/{quizId} ---
      final quizDoc = await _db.collection("quiz").doc(quizId).get();

      final quizTitle =
          (quizDoc.data() != null && quizDoc.data()!.containsKey("title"))
              ? quizDoc.data()!["title"]
              : "Quiz";

      list.add(
        ProgressRecord(
          id: quizId,
          activityName: quizTitle, // <-- Now shows title instead of ID
          completedAt: (data["attemptDate"] is Timestamp)
              ? (data["attemptDate"] as Timestamp).toDate()
              : DateTime.now(),
          score: (data["totalScore"] ?? 0).toDouble(),
          status: data["status"] ?? "completed",
          type: "quiz",
        ),
      );
    }

    return list;
  });
}



  /// STREAM — Combine both manual + quiz
Stream<List<ProgressRecord>> getCombinedProgress(String userId) {
  final manual = getManualProgress(userId);
  final quiz = getQuizProgress(userId);

  return Rx.combineLatest2(
    manual,
    quiz,
    (List<ProgressRecord> m, List<ProgressRecord> q) {
      final all = [...m, ...q];
      all.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return all;
    },
  );
}

}
