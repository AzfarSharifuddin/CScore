class Qualification {
  final String id;
  final String institution;
  final String qualification;

  Qualification({
    required this.id,
    required this.institution,
    required this.qualification,
  });

  Map<String, dynamic> toMap() {
    return {
      'institution': institution,
      'qualification': qualification,
    };
  }

  factory Qualification.fromMap(String id, Map<String, dynamic> data) {
    return Qualification(
      id: id,
      institution: data['institution'] ?? '',
      qualification: data['qualification'] ?? '',
    );
  }
}
