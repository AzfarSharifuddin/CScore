import 'package:flutter/material.dart';
import 'ViewTutorial/viewtutorial.dart';

class LearningPage extends StatelessWidget {
  const LearningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Module'),
        backgroundColor: Colors.grey[200],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navigate to ViewTutorial screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ViewTutorialPage(),
              ),
            );
          },
          child: const Text('View Tutorials'),
        ),
      ),
    );
  }
}
