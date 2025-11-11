import 'package:cloud_firestore/cloud_firestore.dart';

class Qualification {
  final String id;               // Firestore doc ID
  final String teacherId;        // UID of teacher
  final String institution;      // Institution name
  final String qualification;    // Name of qualification (degree/cert)
  final String subjectArea;      // Subject specialization
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Qualification({
    required this.id,
    required this.teacherId,
    required this.institution,
    required this.qualification,
    required this.subjectArea,
    required this.createdAt,
    required this.updatedAt,
  });

  /// ✅ Convert Firestore document to Qualification model
  factory Qualification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Qualification(
      id: doc.id,
      teacherId: data['teacherId'] ?? '',
      institution: data['institution'] ?? '',
      qualification: data['qualification'] ?? '',
      subjectArea: data['subjectArea'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  /// ✅ Convert Qualification model to Firestore format
  Map<String, dynamic> toMap() {
    return {
      'teacherId': teacherId,
      'institution': institution,
      'qualification': qualification,
      'subjectArea': subjectArea,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
