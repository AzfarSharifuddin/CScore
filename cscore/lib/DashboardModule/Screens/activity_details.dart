import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cscore/QuizModule/Models/quiz_model.dart';
import 'package:cscore/QuizModule/Student/attempt_quiz.dart'; // 🔹 Ensure correct import path

class ActivityDetailsPage extends StatelessWidget {
  final String activityId;

  const ActivityDetailsPage({super.key, required this.activityId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Activity Details", style: TextStyle(color: Colors.black87)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('activities').doc(activityId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.event_available_rounded, color: Colors.blue[700], size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            data['title'] ?? '',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Due: ${(data['deadline'] as Timestamp).toDate().toString().substring(0, 10)}",
                      style: const TextStyle(fontSize: 16, color: Colors.redAccent),
                    ),

                    const Divider(height: 25),

                    const Text(
                      "Description",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      data['description'] ?? '',
                      style: const TextStyle(fontSize: 16),
                    ),

                    const Spacer(),

                    if (data.containsKey('quizId') && data['quizId'] != null)
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            final quizDoc = await FirebaseFirestore.instance
                                .collection('quiz')
                                .doc(data['quizId'])
                                .get();

                            if (!quizDoc.exists) return;

                            final quiz = QuizModel.fromDocument(quizDoc);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AttemptQuizPage(quiz: quiz),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            "Go to Quiz",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
