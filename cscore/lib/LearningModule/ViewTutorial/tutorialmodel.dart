class TutorialFile {
  final String fileName;
  final String fileType;
  final String fileUrl;
  final String teacherName;
  final String description;
  final String thumbnailUrl; // 👈 NEW FIELD

  TutorialFile({
    required this.fileName,
    required this.fileType,
    required this.fileUrl,
    required this.teacherName,
    required this.description,
    required this.thumbnailUrl, // 👈 NEW FIELD
  });
}

class Tutorial {
  final String subtopic;
  final List<TutorialFile> files;

  Tutorial({required this.subtopic, required this.files});
}
