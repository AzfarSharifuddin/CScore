import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cscore/ProgressTrackerModule/Services/progress_service.dart';
import 'package:cscore/ProgressTrackerModule/Model/progress_record.dart';
import 'add_progress.dart';
import 'edit_progress_page.dart'; // ✅ Import your edit page

class ViewProgressScreen extends StatelessWidget {
  final ProgressService _progressService = ProgressService();

  ViewProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 🔄 Waiting for Firebase Auth to load
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        // ❌ No user? (should not happen if you added signInAnonymously)
        if (user == null) {
          return const Scaffold(
            body: Center(
              child: Text(
                "You must be logged in to view progress.",
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        }

        final userId = user.uid; // ✅ Finally not null ✅

        return Scaffold(
          appBar: AppBar(title: const Text("My Progress")),
          body: _buildProgressBody(context, userId),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddProgressPage()),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildProgressBody(BuildContext context, String userId) {
    return StreamBuilder<List<ProgressRecord>>(
      stream: _progressService.getProgressStream(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading progress: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final progress = snapshot.data!;

        if (progress.isEmpty) {
          return const Center(
            child: Text(
              'No progress recorded yet.\nTap + to add your first progress!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

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
              subtitle: Text(
                "Score: ${p.score} | ${p.completedAt.toLocal()}",
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red[400]),
                onPressed: () =>
                    _progressService.deleteProgress(userId, p.id),
              ),

              // ✅ NEW: Tap to edit
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProgressPage(record: p),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
