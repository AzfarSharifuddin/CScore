import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'quiz.dart';
import 'package:cscore/DashboardModule/Screens/student_dashboard.dart';

const mainColor = Color.fromRGBO(0, 70, 67, 1);

class ScoreQuizPage extends StatelessWidget {
  final String title;
  final int score;
  final int total;
  final List<Map<String, dynamic>> subjectiveAnswers;

  const ScoreQuizPage({
    super.key,
    required this.title,
    required this.score,
    required this.total,
    required this.subjectiveAnswers,
  });

  @override
  Widget build(BuildContext context) {
    double percentage = (score / total) * 100;

    String message = percentage >= 80
        ? "🎉 Excellent Work!"
        : percentage >= 50
            ? "👏 Good Effort!"
            : "💪 Keep Practicing!";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              Text(
                message,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: mainColor,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "Your Score: $score / $total",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 220),

              CustomPaint(
                size: const Size(180, 180),
                painter: CircularScorePainter(percentage),
                child: Center(
                  child: Text(
                    "${percentage.toStringAsFixed(0)}%",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const QuizListPage()),
                      (_) => false,
                    );
                  },
                  child: const Text(
                    "Back to Quizzes",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: mainColor, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const StudentDashboard()),
                      (_) => false,
                    );
                  },
                  child: const Text(
                    "Back to Dashboard",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: mainColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class CircularScorePainter extends CustomPainter {
  final double percentage;

  CircularScorePainter(this.percentage);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bg = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    final fg = Paint()
      ..shader = const LinearGradient(
        colors: [mainColor, Colors.lightGreenAccent],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bg);

    double sweep = 2 * math.pi * (percentage / 100);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
