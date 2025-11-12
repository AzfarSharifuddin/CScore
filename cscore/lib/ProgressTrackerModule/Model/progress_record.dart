// progress_record.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressRecord {
  final String id;
  final String activityName;
  final DateTime completedAt;
  final double score;
  final String status;
  final String type; // "learning" or "activity"

  ProgressRecord({
    required this.id,
    required this.activityName,
    required this.completedAt,
    required this.score,
    required this.status,
    required this.type,
  });

  factory ProgressRecord.fromMap(Map<String, dynamic> map, String id) {
    // completedAt safe parsing
    DateTime completedAt = DateTime.now();
    final rawCompleted = map['completedAt'];
    if (rawCompleted is Timestamp) {
      completedAt = rawCompleted.toDate();
    } else if (rawCompleted is DateTime) {
      completedAt = rawCompleted;
    }

    // score safe parsing
    double score = 0.0;
    final rawScore = map['score'];
    if (rawScore is num) score = rawScore.toDouble();
    else if (rawScore is String) score = double.tryParse(rawScore) ?? 0.0;

    final status = (map['status'] ?? '').toString();

    final type = (map['type'] ?? 'activity').toString(); // default to activity

    return ProgressRecord(
      id: id,
      activityName: (map['activityName'] ?? '').toString(),
      completedAt: completedAt,
      score: score,
      status: status,
      type: type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'activityName': activityName,
      'completedAt': Timestamp.fromDate(completedAt),
      'score': score,
      'status': status,
      'type': type,
    };
  }

  ProgressRecord copyWith({
    String? id,
    String? activityName,
    DateTime? completedAt,
    double? score,
    String? status,
    String? type,
  }) {
    return ProgressRecord(
      id: id ?? this.id,
      activityName: activityName ?? this.activityName,
      completedAt: completedAt ?? this.completedAt,
      score: score ?? this.score,
      status: status ?? this.status,
      type: type ?? this.type,
    );
  }
}
