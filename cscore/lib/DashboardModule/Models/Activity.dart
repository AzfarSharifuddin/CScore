class Activity {
  String title;
  String date;
  String notes;

  Activity({
    required this.title,
    required this.date,
    required this.notes,
  });

  // Convert object to map (for JSON/Firebase compatibility)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': date,
      'notes': notes,
    };
  }

  // Create object from map
  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      title: map['title'] ?? '',
      date: map['date'] ?? '',
      notes: map['notes'] ?? '',
    );
  }
}

