import 'package:cloud_firestore/cloud_firestore.dart';

class BadgeModel {
  final String badgeId;
  final String title;
  final String iconUrl;
  final DateTime earnedAt;

  BadgeModel({
    required this.badgeId,
    required this.title,
    required this.iconUrl,
    required this.earnedAt,
  });

  factory BadgeModel.fromMap(Map<String, dynamic> data, String id) {
    return BadgeModel(
      badgeId: id,
      title: data['title'] ?? 'Achievement Badge',
      iconUrl: data['iconUrl'] ?? '',
      earnedAt: (data['earnedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'iconUrl': iconUrl,
      'earnedAt': earnedAt,
    };
  }
}
