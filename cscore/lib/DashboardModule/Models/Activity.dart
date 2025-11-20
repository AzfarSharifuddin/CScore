// lib/DashboardModule/Models/Activity.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  final String id;
  final String title;
  final String notes;
  final DateTime date;
  final String type;
  final String quizId;

  Activity({
    required this.id,
    required this.title,
    required this.notes,
    required this.date,
    required this.type,
    required this.quizId,
  });

  // Convert Firestore document to Activity object
  factory Activity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Activity(
      id: doc.id,
      title: data['title'] ?? '',
      notes: data['description'] ?? '',
      date: (data['deadline'] as Timestamp).toDate(),
      type: data['type'] ?? 'Quiz',
      quizId: data['quizId'] ?? '',
    );
  }
}
