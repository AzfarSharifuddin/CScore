import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cscore/QuizModule/Models/quiz_model.dart';
import 'quiz.dart';
import 'package:cscore/DashboardModule/Screens/student_dashboard.dart';

const Color mainColor = Color.fromRGBO(0, 70, 67, 1);

class ScoreQuizPage extends StatelessWidget {
  final QuizModel quiz;
  final int score;
  final int total;

  const ScoreQuizPage({
    super.key,
    required this.quiz,
    required this.score,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    double percentage = (score / total) * 100;

    String message;
    if (percentage >= 80) {
      message = "🎉 Excellent Work!";
    } else if (percentage >= 50) {
      message = "👏 Good Effort!";
    } else {
      message = "💪 Keep Practicing!";
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: mainColor,
                ),
              ),
              const SizedBox(height: 30),

              Text(
                "Your Score: $score / $total",
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),

              const SizedBox(height: 40),

              // ✅ Circular Progress Indicator
              Center(
                child: CustomPaint(
                  size: const Size(180, 180),
                  painter: CircularScorePainter(percentage),
                  child: Center(
                    child: Text(
                      "${percentage.toStringAsFixed(0)}%",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const QuizListPage()),
                  (route) => false,
                ),
                child: const Text(
                  "Back to Quizzes",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),

              const SizedBox(height: 16),

              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: mainColor, width: 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentDashboard()),
                  (route) => false,
                ),
                child: const Text(
                  "Back to Dashboard",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: mainColor),
                ),
              ),
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

    final basePaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, basePaint);

    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [mainColor, Colors.greenAccent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweep = 2 * math.pi * (percentage / 100);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
