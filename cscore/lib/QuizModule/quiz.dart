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
      'title': 'Web Development Fundamentals',
      'category': 'Web Development',
      'difficulty': 'Medium',
      'status': 'Not Attempted',
      'image': 'assets/quiz_assets/html.jpg',
      'description': 'Covers HTML, CSS, and short explanation questions.',
      'questions': webDevMixedQuestions,
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
        title: const Text('Quizzes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: quizzes.length,
        itemBuilder: (context, index) {
          final quiz = quizzes[index];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ViewQuizPage(quizData: quiz)),
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
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
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
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(quiz['title'],
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(quiz['category'],
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[600])),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(quiz['difficulty'],
                                    style: TextStyle(
                                        color: Colors.green[800],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12)),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                quiz['status'],
                                style: TextStyle(
                                    color: quiz['status'] == 'Attempted'
                                        ? Colors.blue
                                        : Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Icon(Icons.arrow_forward_ios,
                        color: Colors.grey, size: 18),
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

// Mixed quiz data with both question types
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
