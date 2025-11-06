import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String title;
  final String description;
  final String date;
  final String createdBy;

  Announcement({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.createdBy,
  });

  factory Announcement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Announcement(
      id: doc.id,
      title: data['Title'] ?? '',
      description: data['Description'] ?? '',
      date: data['Date'] ?? '',
      createdBy: data['createdBy'] ?? '',
    );
  }
}
