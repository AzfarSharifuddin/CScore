import 'package:cloud_firestore/cloud_firestore.dart';


class ProgressRecord {
  final String id;
  final String activityName;
  final DateTime completedAt;
  final double score;
  final String status;

  ProgressRecord({
    required this.id,
    required this.activityName,
    required this.completedAt,
    required this.score,
    required this.status,
  });

  factory ProgressRecord.fromMap(Map<String, dynamic> map, String id) {
    return ProgressRecord(
      id: id,
      activityName: map['activityName'],
      completedAt: (map['completedAt'] as Timestamp).toDate(),
      score: map['score'].toDouble(),
      status: map['status'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'activityName': activityName,
      'completedAt': completedAt,
      'score': score,
      'status': status,
    };
  }
}
