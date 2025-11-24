// lib/QuizModule/Management/view_quiz_attempts.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cscore/QuizModule/Models/student_attempt_row.dart';
import 'package:cscore/QuizModule/Management/student_attempt_tile.dart';
import 'edit_quiz.dart';

const Color mainColor = Color.fromRGBO(0, 70, 67, 1);

enum SortBy {
  highestScore,
  lowestScore,
  latestAttempt,
  oldestAttempt,
  mostAttempts,
  leastAttempts,
}

class ViewQuizAttemptsPage extends StatefulWidget {
  final String quizId;
  final String quizTitle;

  const ViewQuizAttemptsPage({
    super.key,
    required this.quizId,
    required this.quizTitle,
  });

  @override
  State<ViewQuizAttemptsPage> createState() => _ViewQuizAttemptsPageState();
}

class _ViewQuizAttemptsPageState extends State<ViewQuizAttemptsPage> {
  SortBy _sortBy = SortBy.latestAttempt;

  /// SAFE version of attemptsStream()
  Stream<List<StudentAttemptRow>> attemptsStream() {
    final quizId = widget.quizId;

    return FirebaseFirestore.instance
        .collectionGroup('quizProgress')
        .snapshots()
        .asyncMap((snap) async {
      final rows = <StudentAttemptRow>[];

      for (final doc in snap.docs) {
        /// Filter: Only this quiz
        if (doc.id != quizId) continue;

        final parent = doc.reference.parent.parent;
        if (parent == null) continue;

        final userId = parent.id;
        final data = doc.data();

        // Fetch user info
        final userSnap = await FirebaseFirestore.instance
            .collection('user')
            .doc(userId)
            .get();

        final userData = userSnap.data();
        final userName = userData?['name'] ?? userData?['email'] ?? 'Unknown';
        final userEmail = userData?['email'] ?? '';

        rows.add(StudentAttemptRow.fromProgressDoc(
          userId: userId,
          progressData: data,
          userName: userName,
          userEmail: userEmail,
        ));
      }

      // Sorting system
      rows.sort((a, b) {
        switch (_sortBy) {
          case SortBy.highestScore:
            return b.currentScore.compareTo(a.currentScore);
          case SortBy.lowestScore:
            return a.currentScore.compareTo(b.currentScore);
          case SortBy.mostAttempts:
            return b.attemptCount.compareTo(a.attemptCount);
          case SortBy.leastAttempts:
            return a.attemptCount.compareTo(b.attemptCount);
          case SortBy.oldestAttempt:
            return (a.attemptDate ?? DateTime(0))
                .compareTo(b.attemptDate ?? DateTime(0));
          case SortBy.latestAttempt:
          default:
            return (b.attemptDate ?? DateTime(0))
                .compareTo(a.attemptDate ?? DateTime(0));
        }
      });

      return rows;
    });
  }

  String _sortLabel(SortBy s) {
    switch (s) {
      case SortBy.highestScore:
        return 'Highest Score';
      case SortBy.lowestScore:
        return 'Lowest Score';
      case SortBy.latestAttempt:
        return 'Latest Attempt';
      case SortBy.oldestAttempt:
        return 'Oldest Attempt';
      case SortBy.mostAttempts:
        return 'Most Attempts';
      case SortBy.leastAttempts:
        return 'Least Attempts';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.quizTitle} Attempts"),
        backgroundColor: mainColor,
      ),
      body: Column(
        children: [
          // Sorting section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Text("Sort by:",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<SortBy>(
                    value: _sortBy,
                    isExpanded: true,
                    onChanged: (s) => setState(() => _sortBy = s!),
                    items: SortBy.values
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(_sortLabel(s))))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Attempts list
          Expanded(
            child: StreamBuilder<List<StudentAttemptRow>>(
              stream: attemptsStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text("Error: ${snap.error}"));
                }

                final rows = snap.data ?? [];
                if (rows.isEmpty) {
                  return const Center(child: Text("No attempts yet."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  itemCount: rows.length,
                  itemBuilder: (_, i) => StudentAttemptTile(row: rows[i]),
                );
              },
            ),
          ),

          // Bottom actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EditQuizPage(quizId: widget.quizId),
                      ),
                    );
                  },
                  child: const Text(
                    "Edit Quiz",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed: null, // delete disabled (per your spec)
                  child:
                      const Text("Delete Quiz", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
