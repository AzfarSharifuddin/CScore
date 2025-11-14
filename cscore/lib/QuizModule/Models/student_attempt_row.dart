// lib/QuizModule/Models/student_attempt_row.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentAttemptRow {
  final String userId;
  final String userName;
  final String userEmail;

  final int attemptCount;
  final double currentScore;
  final DateTime? attemptDate;

  StudentAttemptRow({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.attemptCount,
    required this.currentScore,
    required this.attemptDate,
  });

  factory StudentAttemptRow.fromProgressDoc({
    required String userId,
    required Map<String, dynamic> progressData,
    required String? userName,
    required String? userEmail,
  }) {
    return StudentAttemptRow(
      userId: userId,
      userName: userName ?? "Unknown User",
      userEmail: userEmail ?? "",

      attemptCount: progressData["attemptCount"] ?? 0,

      currentScore:
          (progressData["currentScore"] ?? 0).toDouble(),

      // 🔥 FIXED: read the correct field from Firestore
      attemptDate: progressData["attemptDate"] != null
          ? (progressData["attemptDate"] as Timestamp).toDate()
          : null,
    );
  }
}
