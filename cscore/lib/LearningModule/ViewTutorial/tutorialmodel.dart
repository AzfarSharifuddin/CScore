class TutorialFile {
  final String fileName;
  final String fileType;
  final String fileUrl;
  final String teacherName;
  final String uploadedBy; // ✅ Stored but not displayed
  final String description;
  final String thumbnailUrl;

  TutorialFile({
    required this.fileName,
    required this.fileType,
    required this.fileUrl,
    required this.teacherName,
    required this.uploadedBy, // ✅ Important for permissions
    required this.description,
    required this.thumbnailUrl,
  });
}

class Tutorial {
  final String subtopic;
  final List<TutorialFile> files;

  Tutorial({required this.subtopic, required this.files});
}
