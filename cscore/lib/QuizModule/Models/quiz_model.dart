// quiz_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String quizType; // "exercise" | "exam"
  final int duration; // minutes
  final DateTime deadline;
  final int numQuestions;
  final String image; // asset image path
  final String createdBy;
  final DateTime createdAt;
  final List<QuestionModel> questions;
  final int maxAttempts; // new: limit attempts (optional, default 1)

  QuizModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.quizType,
    required this.duration,
    required this.deadline,
    required this.numQuestions,
    required this.image,
    required this.createdBy,
    required this.createdAt,
    required this.questions,
    required this.maxAttempts,
  });

  factory QuizModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final deadlineField = data['deadline'];
    DateTime parsedDeadline;
    if (deadlineField is Timestamp) parsedDeadline = deadlineField.toDate();
    else if (deadlineField is DateTime) parsedDeadline = deadlineField;
    else parsedDeadline = DateTime.now();

    final createdAtField = data['createdAt'];
    DateTime parsedCreatedAt;
    if (createdAtField is Timestamp) parsedCreatedAt = createdAtField.toDate();
    else if (createdAtField is DateTime) parsedCreatedAt = createdAtField;
    else parsedCreatedAt = DateTime.now();

    final rawQuestions = data['questions'] as List<dynamic>? ?? [];

    return QuizModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      quizType: data['quizType'] ?? data['difficulty'] ?? 'exercise',
      duration: (data['duration'] is num) ? (data['duration'] as num).toInt() : 0,
      deadline: parsedDeadline,
      numQuestions: (data['numQuestions'] is num) ? (data['numQuestions'] as num).toInt() : rawQuestions.length,
      image: data['image'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: parsedCreatedAt,
      questions: rawQuestions.map((q) {
        if (q is Map<String, dynamic>) return QuestionModel.fromMap(q);
        if (q is Map) return QuestionModel.fromMap(Map<String, dynamic>.from(q));
        return QuestionModel(type: 'objective', question: '', options: [], answer: 0);
      }).toList(),
      maxAttempts: (data['maxAttempts'] is num) ? (data['maxAttempts'] as num).toInt() : 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'quizType': quizType,
      'duration': duration,
      'deadline': Timestamp.fromDate(deadline),
      'numQuestions': numQuestions,
      'image': image,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'questions': questions.map((q) => q.toMap()).toList(),
      'maxAttempts': maxAttempts,
    };
  }
}

class QuestionModel {
  final String type; // "objective" | "subjective"
  final String question;
  final List<String>? options; // objective only
  final int? answer; // objective only (index)
  final String? expectedAnswer; // subjective only
  final bool? aiEvaluated; // subjective only

  QuestionModel({
    required this.type,
    required this.question,
    this.options,
    this.answer,
    this.expectedAnswer,
    this.aiEvaluated,
  });

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      type: map['type'] ?? 'objective',
      question: map['question'] ?? '',
      options: map['options'] != null ? List<String>.from(map['options']) : null,
      answer: map['answer'] != null ? (map['answer'] is num ? (map['answer'] as num).toInt() : null) : null,
      expectedAnswer: map['expectedAnswer'],
      aiEvaluated: map['aiEvaluated'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{'type': type, 'question': question};
    if (type == 'objective') {
      map['options'] = options ?? [];
      if (answer != null) map['answer'] = answer;
    } else {
      map['expectedAnswer'] = expectedAnswer ?? '';
      map['aiEvaluated'] = aiEvaluated ?? false;
    }
    return map;
  }
}
