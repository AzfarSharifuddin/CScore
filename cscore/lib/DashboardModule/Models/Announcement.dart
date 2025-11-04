class Announcement {
  String title;
  String description;
  String date;

  Announcement({
    required this.title,
    required this.description,
    required this.date,
  });

  // Convert object to map (useful for later Firebase or local storage)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': date,
    };
  }

  // Create object from map
  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
    );
  }
}
