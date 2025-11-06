import 'package:flutter/material.dart';
import 'dart:math';
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
final _rnd = Random();

/// A small set of templates for more human-like phrasing.
final List<String> _positiveTemplates = [
  "Correct — nice work! {explain}",
  "Good job — that's right. {explain}",
  "That's correct. {explain}",
  "Exactly — well done. {explain}"
];

final List<String> _negativeTemplates = [
  "Not quite — {explain}",
  "That's incorrect. {explain}",
  "Close, but not correct. {explain}",
  "I can see the idea, but that's wrong. {explain}"
];

/// Model short answers / keywords for subjective questions (index -> data).
/// Populate with expected points to match user responses simply.
final Map<int, Map<String, dynamic>> _subjectiveModels = {
  // index 1: "Explain the purpose of the <div> tag in HTML."
  1: {
    'keywords': ['container', 'group', 'styling', 'layout', 'block-level', 'wrapper'],
    'modelAnswer':
        'The <div> tag is a generic block-level container used to group other elements together so you can '
            'apply CSS styles or layout rules to the group. It has no semantic meaning by itself.'
  },
  // index 3: "Write a short CSS rule to make all <h1> text blue."
  3: {
    'keywords': ['h1', 'color', 'blue', 'h1 {', 'color: blue'],
    'modelAnswer': 'Example: `h1 { color: blue; }` — this selects all <h1> elements and sets their text color to blue.'
  }
};

/// Evaluate a quiz's questions given userAnswers.
/// - questions: list of question maps (as in your file).
/// - userAnswers: map of questionIndex -> answer
///     * For objective q: answer should be an int index corresponding to the chosen option.
///     * For subjective q: answer should be a String text response.
/// Returns a list of result maps: {index, correct (bool), message (String), detail (Map)}
List<Map<String, dynamic>> evaluateQuizAnswers(
    List<Map<String, dynamic>> questions, Map<int, dynamic> userAnswers) {
  final results = <Map<String, dynamic>>[];

  for (var i = 0; i < questions.length; i++) {
    final q = questions[i];
    final type = q['type'] as String? ?? 'objective';
    final questionText = q['question'] as String? ?? '';
    final userAnswer = userAnswers.containsKey(i) ? userAnswers[i] : null;

    if (type == 'objective') {
      final correctIndex = q['answer'] as int?;
      final options = (q['options'] as List<dynamic>?)?.cast<String>() ?? [];

      if (userAnswer is int && correctIndex != null) {
        final bool isCorrect = userAnswer == correctIndex;
        final explain = isCorrect
            ? "The correct tag is ${options[correctIndex]} which inserts a line break."
            : "You picked ${userAnswer < options.length ? options[userAnswer] : 'an invalid option'}. "
                "The correct answer is ${options[correctIndex]}.";
        final template = isCorrect ? _pickRandom(_positiveTemplates) : _pickRandom(_negativeTemplates);
        final message = template.replaceFirst('{explain}', explain);

        results.add({
          'index': i,
          'type': 'objective',
          'question': questionText,
          'userAnswer': userAnswer,
          'correct': isCorrect,
          'message': message,
          'detail': {
            'correctIndex': correctIndex,
            'correctOption': correctIndex < options.length ? options[correctIndex] : null,
            'allOptions': options,
          }
        });
      } else {
        // missing or invalid answer
        final message = "No valid answer provided for this objective question. Provide the option index.";
        results.add({
          'index': i,
          'type': 'objective',
          'question': questionText,
          'userAnswer': userAnswer,
          'correct': false,
          'message': message,
          'detail': {'expected': 'int option index'}
        });
      }
    } else if (type == 'subjective') {
      final userText = userAnswer is String ? userAnswer.trim() : '';
      final model = _subjectiveModels[i];
      if (userText.isEmpty) {
        results.add({
          'index': i,
          'type': 'subjective',
          'question': questionText,
          'userAnswer': userAnswer,
          'correct': false,
          'message': "No answer provided. Try to explain your reasoning or give a short rule/example.",
          'detail': {'modelAnswer': model != null ? model['modelAnswer'] : null}
        });
      } else if (model != null) {
        final keywords = (model['keywords'] as List).cast<String>();
        final matches = _countKeywordMatches(userText.toLowerCase(), keywords);
        // simple threshold: if >= 2 keywords found or contains model snippet, mark correct
        final bool isCorrect = matches >= 2 || userText.toLowerCase().contains('h1') && userText.toLowerCase().contains('color');

        final explain = isCorrect
            ? "Your answer includes the important points (${_summarizeKeywords(matches, keywords)})."
            : "Your answer misses some expected points. ${model['modelAnswer']}";

        final template = isCorrect ? _pickRandom(_positiveTemplates) : _pickRandom(_negativeTemplates);
        final message = template.replaceFirst('{explain}', explain);

        results.add({
          'index': i,
          'type': 'subjective',
          'question': questionText,
          'userAnswer': userText,
          'correct': isCorrect,
          'message': message,
          'detail': {
            'keywordMatches': matches,
            'modelAnswer': model['modelAnswer'],
            'expectedKeywords': keywords,
          }
        });
      } else {
        // no model available — give generic supportive feedback
        final message =
            _pickRandom(_negativeTemplates).replaceFirst('{explain}', 'I don\'t have a model answer for this item, but aim to be specific and include examples.');
        results.add({
          'index': i,
          'type': 'subjective',
          'question': questionText,
          'userAnswer': userText,
          'correct': false,
          'message': message,
          'detail': {}
        });
      }
    } else {
      // unknown type
      results.add({
        'index': i,
        'type': type,
        'question': questionText,
        'userAnswer': userAnswer,
        'correct': false,
        'message': 'Unknown question type.',
        'detail': {}
      });
    }
  }

  return results;
}

/// Helper: count how many keywords appear in the text.
int _countKeywordMatches(String text, List<String> keywords) {
  var count = 0;
  for (var k in keywords) {
    if (text.contains(k.toLowerCase())) count++;
  }
  return count;
}

/// Small human-like summary of which keywords matched (not exhaustive).
String _summarizeKeywords(int count, List<String> keywords) {
  if (count <= 0) return 'none of the expected keywords';
  if (count == 1) return 'one of the expected keywords';
  return '$count of the expected keywords';
}

String _pickRandom(List<String> pool) => pool[_rnd.nextInt(pool.length)];