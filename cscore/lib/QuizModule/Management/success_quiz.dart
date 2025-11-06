import 'package:flutter/material.dart';
import '../student/quiz.dart'; // for viewing quizzes
import 'package:cscore/DashboardModule/Screens/teacher_dashboard.dart'; // adjust this import if your file name differs

const mainColor = Color.fromRGBO(0, 70, 67, 1);

class SuccessQuizPage extends StatelessWidget {
  const SuccessQuizPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ Big checkmark icon
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: mainColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: mainColor, size: 70),
            ),
            const SizedBox(height: 30),

            // 🎉 Success message
            const Text(
              "Quiz Created Successfully!",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: mainColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              "Your quiz has been added and is now visible to students.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 50),

            // ✅ Back to Dashboard button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: mainColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const TeacherDashboard()),
                (route) => false,
              ),
              child: const Text(
                "Back to Dashboard",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),

            // 📚 View Quizzes button
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: mainColor, width: 2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const QuizListPage()),
                (route) => false,
              ),
              child: const Text(
                "View Quizzes",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: mainColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
