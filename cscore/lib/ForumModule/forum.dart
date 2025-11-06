import 'package:flutter/material.dart';
import 'create_post_screen.dart';

final List<Map<String, String>> mockForums = [
  {'title': 'Question about Final Exam', 'author': 'Aniqq', 'date': 'Nov 1, 2025'},
  {'title': 'Discussion on Course Grading', 'author': 'Leonard', 'date': 'Oct 28, 2025'},
  {'title': 'Help with Software Installation', 'author': 'Admin', 'date': 'Oct 25, 2025'},
];

class Forum extends StatefulWidget {
  const Forum({super.key});

  @override
  State<Forum> createState() => _ForumState();
}

class _ForumState extends State<Forum> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forum'),
        backgroundColor: Colors.grey[200],
      ),
      body: ListView.builder(
        itemCount: mockForums.length,
        itemBuilder: (context, index) {
          final forum = mockForums[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(
                forum['title']!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Author: ${forum['author']} | Date: ${forum['date']}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                print('Opening Post: ${forum['title']}');
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}