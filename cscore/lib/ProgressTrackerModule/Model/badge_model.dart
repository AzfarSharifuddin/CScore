import 'package:cloud_firestore/cloud_firestore.dart';


class BadgeModel {
  final String id;
  final String title;
  final String iconUrl;
  final String description;
  final String status;
  final String quizId;
  final DateTime earnedAt;

  BadgeModel({
    required this.id,
    required this.title,
    required this.iconUrl,
    required this.description,
    required this.status,
    required this.quizId,
    required this.earnedAt,
  });

  factory BadgeModel.fromMap(Map<String, dynamic> data, String id) {
    return BadgeModel(
      id: id,
      title: data['title'] ?? '',
      iconUrl: data['iconUrl'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'earned',
      quizId: data['quizId'] ?? '',
      earnedAt: (data['earnedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
