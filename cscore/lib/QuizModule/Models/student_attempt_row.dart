// lib/QuizModule/Models/student_attempt_row.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentAttemptRow {
  final String userId;
  final String userName;
  final String userEmail;
  final String quizId; 

  final int attemptCount;
  final double currentScore;
  final DateTime? attemptDate;

  StudentAttemptRow({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.quizId, 
    required this.attemptCount,
    required this.currentScore,
    required this.attemptDate,
  });

  factory StudentAttemptRow.fromProgressDoc({
    required String userId,
    required Map<String, dynamic> progressData,
    required String? userName,
    required String? userEmail,
    required String quizId,
  }) {
    return StudentAttemptRow(
      userId: userId,
      userName: userName ?? "Unknown User",
      userEmail: userEmail ?? "",
      quizId: quizId, 

      attemptCount: progressData["attemptCount"] ?? 0,

      currentScore:
          (progressData["currentScore"] ?? 0).toDouble(),

      attemptDate: progressData["attemptDate"] != null
          ? (progressData["attemptDate"] as Timestamp).toDate()
          : null,
    );
  }
}