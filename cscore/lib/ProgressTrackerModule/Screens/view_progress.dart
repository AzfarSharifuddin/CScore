import 'package:flutter/material.dart';
import 'package:cscore/ProgressTrackerModule/Services/progress_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
// We no longer need demo_config.dart for the User ID
// import 'package:cscore/ProgressTrackerModule/config/demo_config.dart';

class ViewProgressScreen extends StatelessWidget {
  // 🔹 Use the ProgressService
  final ProgressService _progressService = ProgressService();
  // 🔹 Get the current user from Firebase Auth
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  ViewProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Progress")),
      body: _buildProgressBody(),
    );
  }

  Widget _buildProgressBody() {
    // 🔹 1. Check if user is logged in
    if (userId == null) {
      return const Center(
        child: Text(
          'You must be logged in to view progress.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    // 🔹 2. Use the StreamBuilder with the valid userId
    return StreamBuilder(
      stream: _progressService.getProgressStream(userId!), // Pass the non-null userId
      builder: (context, snapshot) {
        
        // 🔹 3. Handle Errors (FIXED)
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading progress: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        // Handle Loading
        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final progress = snapshot.data!;

        // 🔹 4. Handle Empty State (FIXED)
        if (progress.isEmpty) {
          return const Center(
            child: Text(
              'No progress recorded yet.\nComplete a quiz or module!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        // Handle Success
        return ListView.builder(
          itemCount: progress.length,
          itemBuilder: (context, i) {
            final p = progress[i];
            return ListTile(
              leading: Icon(
                p.activityName.toLowerCase().contains('quiz')
                    ? Icons.quiz_rounded
                    : Icons.school_rounded,
                color: Colors.blue[600],
              ),
              title: Text(p.activityName),
              subtitle: Text("Score: ${p.score} | ${p.completedAt}"),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red[400]),
                onPressed: () => _progressService.deleteProgress(userId!, p.id),
              ),
            );
          },
        );
      },
    );
  }
}

// 🔹 MOCK DATA (So this file can run)
// You should have these classes defined in your actual project
class ProgressService {
  Stream<List<ProgressItem>> getProgressStream(String userId) {
    // This is a mock stream. Your real service would call Firebase.
    return Stream.value([
      ProgressItem(id: '1', activityName: 'HTML Basics Quiz', score: 85, completedAt: '2025-11-05'),
      ProgressItem(id: '2', activityName: 'CSS Module 1', score: 100, completedAt: '2025-11-06'),
    ]);
  }

  void deleteProgress(String userId, String progressId) {
    // This is a mock function.
    print('Deleting progress $progressId for user $userId');
  }
}

class ProgressItem {
  final String id;
  final String activityName;
  final int score;
  final String completedAt;

  ProgressItem({
    required this.id,
    required this.activityName,
    required this.score,
    required this.completedAt,
  });
}