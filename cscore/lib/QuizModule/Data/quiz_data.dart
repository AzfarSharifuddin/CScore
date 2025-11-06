import 'package:flutter/material.dart';

// ✅ Mixed demo questions
final List<Map<String, dynamic>> webDevMixedQuestions = [
  {
    'type': 'objective',
    'question': 'Which tag creates a line break in HTML?',
    'options': ['<lb>', '<br>', '<break>', '<newline>'],
    'answer': 1,
  },
  {
    'type': 'subjective',
    'question': 'Explain the purpose of the <div> tag in HTML.',
  },
  {
    'type': 'objective',
    'question': 'Which property changes the text color in CSS?',
    'options': ['font-style', 'background-color', 'color', 'text-decoration'],
    'answer': 2,
  },
  {
    'type': 'subjective',
    'question': 'Write a short CSS rule to make all <h1> text blue.',
  },
];

// ✅ Helper to format DateTime → dd/mm/yyyy
String formatDeadline(DateTime date) {
  return "${date.day.toString().padLeft(2, '0')}/"
         "${date.month.toString().padLeft(2, '0')}/"
         "${date.year}";
}

// ✅ GLOBAL quiz list (mutable)
List<Map<String, dynamic>> sampleQuizzes = [
  {
    'title': 'Web Development Fundamentals',
    'category': 'Web Development',
    'difficulty': 'Medium',
    'status': 'Not Attempted',
    'image': 'assets/quiz_assets/html.jpg',
    'description': 'Covers HTML, CSS, and short explanation questions.',
    'duration': 10,  
    'deadline': DateTime(2025, 12, 31),
    'questions': webDevMixedQuestions,
  },
];
