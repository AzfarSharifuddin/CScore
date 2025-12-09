// lib/QuizModule/Management/student_attempt_tile.dart
import 'package:flutter/material.dart';
import 'package:cscore/QuizModule/Models/student_attempt_row.dart';
// ⭐️ NEW IMPORT
import 'package:cscore/QuizModule/Management/view_attempt_details_page.dart'; 

const Color mainColor = Color.fromRGBO(0, 70, 67, 1);

class StudentAttemptTile extends StatelessWidget {
  final StudentAttemptRow row;

  const StudentAttemptTile({super.key, required this.row});

  String _formatDate(DateTime? d) {
    if (d == null) return "-";
    return "${d.day}/${d.month}/${d.year}";
  }

  @override
  Widget build(BuildContext context) {
    // ⭐️ WRAP THE CARD WITH INKWELL
    return InkWell(
      onTap: () {
        // Navigate to the new page, passing the row data
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ViewAttemptDetailsPage(attemptRow: row),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        // The rest of the content remains inside the Card's child
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PROFILE ICON
              CircleAvatar(
                radius: 26,
                backgroundColor: mainColor.withOpacity(0.12),
                child: Text(
                  row.userName.isNotEmpty
                      ? row.userName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 18,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // NAME + EMAIL
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      row.userEmail,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // SCORE + ATTEMPTS + DATE
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Score: ${row.currentScore.toStringAsFixed(1)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Attempts: ${row.attemptCount}",
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ⭐ LAST ATTEMPT DATE (RESTORED)
                  Text(
                    "Last: ${_formatDate(row.attemptDate)}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}