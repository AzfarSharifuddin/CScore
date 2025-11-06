// QuizModule/data/quiz_data.dart

final List<Map<String, dynamic>> sampleQuizzes = [
  {
    'title': 'Web Development Fundamentals',
    'category': 'Web Development',
    'difficulty': 'Medium',
    'status': 'Not Attempted',
    'image': 'assets/quiz_assets/html.jpg',
    'description': 'Covers HTML, CSS, and short explanation questions.',
    'questions': [
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
    ],
  },
];
