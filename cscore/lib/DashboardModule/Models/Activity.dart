class Activity {
  final String title;
  final String date;
  final String notes;

  Activity({
    required this.title,
    required this.date,
    required this.notes,
  });

  // Convert object to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': date,
      'notes': notes,
    };
  }

  // Create object from Firestore map
  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      title: map['title'] ?? '',
      date: map['date'] ?? '',
      notes: map['notes'] ?? '',
    );
  }
}
