import 'package:cloud_firestore/cloud_firestore.dart';

class TutorialFile {
  final String fileName;
  final String fileType;
  final String fileUrl;
  final String teacherName;
  final String uploadedBy;
  final String description;
  final String thumbnailUrl;
  final Timestamp? modifiedDate;
  final String storagePath;
  String? localModifiedDate; // used for offline version validation

  TutorialFile({
    required this.fileName,
    required this.fileType,
    required this.fileUrl,
    required this.teacherName,
    required this.uploadedBy,
    required this.description,
    required this.storagePath,
    required this.thumbnailUrl,
    this.modifiedDate,
    this.localModifiedDate,
  });
}

class Tutorial {
  final String subtopic;
  final List<TutorialFile> files;

  Tutorial({required this.subtopic, required this.files});
}
