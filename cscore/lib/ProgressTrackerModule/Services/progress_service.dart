import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cscore/ProgressTrackerModule/Model/progress_record.dart';

class ProgressService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addProgress(String userId, ProgressRecord record) async {
    await _db
        .collection('progress')
        .doc(userId)
        .collection('records')
        .add(record.toMap());
  }

    Future<void> updateProgress(String userId, ProgressRecord record) async {
  await FirebaseFirestore.instance
      .collection('progress')
      .doc(userId)
      .collection('records')
      .doc(record.id)
      .update(record.toMap());
}


  Future<void> deleteProgress(String userId, String recordId) async {
    await _db
        .collection('progress')
        .doc(userId)
        .collection('records')
        .doc(recordId)
        .delete();
  }


  Stream<List<ProgressRecord>> getProgressStream(String userId) {
    return _db
        .collection('progress')
        .doc(userId)
        .collection('records')
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProgressRecord.fromMap(doc.data(), doc.id))
            .toList());
  }
}
