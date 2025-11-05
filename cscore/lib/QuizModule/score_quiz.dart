import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'quiz.dart';
import 'package:cscore/DashboardModule/Screens/student_dashboard.dart'; // 👈 make sure this import matches your file name

class ScoreQuizPage extends StatelessWidget {
  final String title;
  final int score;
  final int total;
  final List<Map<String, dynamic>> subjectiveAnswers; // unused for now

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

    // 🎯 Dynamic feedback message
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
              // 🏆 Feedback message (top)
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 40),

              // 🧾 Your Score line
              Text(
                "Your Score: $score / $total",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 220),

              // 🌀 Circular Meter (percentage only inside)
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

              // ✅ Back to Quizzes button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 50, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const QuizListPage()),
                  (route) => false,
                ),
                child: const Text(
                  "Back to Quizzes",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🏠 Back to Dashboard button
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.green, width: 2),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 50, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                    color: Colors.green,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🌀 Custom Circular Progress Painter
class CircularScorePainter extends CustomPainter {
  final double percentage;

  CircularScorePainter(this.percentage);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background ring
    final basePaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Progress ring (gradient)
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.green, Colors.lightGreenAccent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Base circle
    canvas.drawCircle(center, radius, basePaint);

    // Progress arc
    double sweepAngle = 2 * math.pi * (percentage / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
