import 'package:cloud_firestore/cloud_firestore.dart';

class QuizModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final int duration; // minutes
  final DateTime deadline;
  final int numQuestions;
  final String image; // asset image path
  final String createdBy;
  final DateTime createdAt;
  final String status;
  final List<QuestionModel> questions;

  QuizModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.duration,
    required this.deadline,
    required this.numQuestions,
    required this.image,
    required this.createdBy,
    required this.createdAt,
    required this.status,
    required this.questions,
  });

  /// ✅ Firestore → Dart Model
  factory QuizModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return QuizModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      difficulty: data['difficulty'] ?? 'Easy',
      duration: data['duration'] ?? 0,
      deadline: (data['deadline'] as Timestamp).toDate(),
      numQuestions: data['numQuestions'] ?? 0,
      image: data['image'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'Not Attempted',
      questions: (data['questions'] as List<dynamic>)
          .map((q) => QuestionModel.fromMap(q))
          .toList(),
    );
  }

  /// ✅ Dart → Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'duration': duration,
      'deadline': Timestamp.fromDate(deadline),
      'numQuestions': numQuestions,
      'image': image,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'questions': questions.map((q) => q.toMap()).toList(),
    };
  }
}

//////////////////////////////////////////////////////////////////
//                     QUESTION MODEL                           //
//////////////////////////////////////////////////////////////////

class QuestionModel {
  final String type; // "objective" or "subjective"
  final String question;
  final List<String>? options; // only for objective
  final int? answer; // only for objective
  final String? expectedAnswer; // ✅ for subjective

  QuestionModel({
    required this.type,
    required this.question,
    this.options,
    this.answer,
    this.expectedAnswer,
  });

  /// Firestore → Dart
  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      type: map['type'] ?? 'objective',
      question: map['question'] ?? '',
      options:
          map['options'] != null ? List<String>.from(map['options']) : null,
      answer: map['answer'],
      expectedAnswer: map['expectedAnswer'], // ✅ support AI marking
    );
  }

  /// Dart → Firestore
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'question': question,
      if (options != null) 'options': options,
      if (answer != null) 'answer': answer,
      if (expectedAnswer != null && expectedAnswer!.isNotEmpty)
        'expectedAnswer': expectedAnswer,
    };
  }
}
