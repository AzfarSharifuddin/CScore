import 'package:flutter/material.dart';
import 'view_quiz.dart';

class QuizListPage extends StatefulWidget {
  const QuizListPage({super.key});

  @override
  State<QuizListPage> createState() => _QuizListPageState();
}

class _QuizListPageState extends State<QuizListPage> {
  final List<Map<String, dynamic>> quizzes = [
    {
      'title': 'HTML Quiz',
      'category': 'Web Development',
      'difficulty': 'Easy',
      'status': 'Not Attempted',
      'image': 'assets/html.png',
      'description': 'Test your knowledge of HTML tags and structure.',
      'questions': htmlQuestions,
    },
    {
      'title': 'CSS Quiz',
      'category': 'Web Development',
      'difficulty': 'Medium',
      'status': 'Not Attempted',
      'image': 'assets/css.png',
      'description': 'Assess your understanding of CSS selectors and styling rules.',
      'questions': cssQuestions,
    },
    {
      'title': 'JavaScript Quiz',
      'category': 'Web Development',
      'difficulty': 'Hard',
      'status': 'Not Attempted',
      'image': 'assets/js.png',
      'description': 'Challenge your JS skills with tricky code logic questions.',
      'questions': jsQuestions,
    },
  ];

  void markAsAttempted(String title) {
    setState(() {
      final index = quizzes.indexWhere((q) => q['title'] == title);
      if (index != -1) quizzes[index]['status'] = 'Attempted';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        title: const Text(
          'Quizzes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.builder(
        itemCount: quizzes.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final quiz = quizzes[index];
          return GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ViewQuizPage(quizData: quiz),
                ),
              );
              if (result == true) markAsAttempted(quiz['title']);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Image on the left
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    child: Image.asset(
                      quiz['image'],
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Quiz Info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quiz['title'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            quiz['category'],
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  quiz['difficulty'],
                                  style: TextStyle(
                                    color: Colors.green[800],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                quiz['status'],
                                style: TextStyle(
                                  color: quiz['status'] == 'Attempted'
                                      ? Colors.blue
                                      : Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Arrow Icon on the right
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Mock Question Data
final List<Map<String, dynamic>> htmlQuestions = [
  {'question': 'Which tag creates a line break?', 'options': ['<lb>', '<br>', '<break>', '<newline>'], 'answer': 1},
  {'question': 'Which tag defines a hyperlink?', 'options': ['<link>', '<a>', '<href>', '<url>'], 'answer': 1},
];

final List<Map<String, dynamic>> cssQuestions = [
  {'question': 'Which property changes text color?', 'options': ['font-style', 'background-color', 'color', 'text-decoration'], 'answer': 2},
  {'question': 'How do you center align text in CSS?', 'options': ['align: center;', 'text-align: center;', 'center-text;', 'text-style: center;'], 'answer': 1},
];

final List<Map<String, dynamic>> jsQuestions = [
  {'question': 'Which keyword declares a variable in JavaScript?', 'options': ['var', 'let', 'const', 'all of the above'], 'answer': 3},
  {'question': 'What is the output of: console.log(typeof null)?', 'options': ['null', 'undefined', 'object', 'number'], 'answer': 2},
];
