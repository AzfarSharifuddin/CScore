import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ActivityDetailsPage extends StatelessWidget {
  final String activityId;
  final bool isTeacher; // 👈 ADD THIS

  const ActivityDetailsPage({
    super.key,
    required this.activityId,
    this.isTeacher = false, // 👈 default for students
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Activity Details", style: TextStyle(color: Colors.black87)),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: isTeacher
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.pushNamed(context, '/editActivity', arguments: activityId);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(context),
                ),
              ]
            : null,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('activity').doc(activityId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final deadlineDate = (data['deadline'] as Timestamp).toDate();
          final formattedDate = DateFormat('yyyy-MM-dd').format(deadlineDate);
          final daysLeft = deadlineDate.difference(DateTime.now()).inDays;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.event_available_rounded, color: Colors.blue[700], size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(data['title'] ?? '',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // Deadline display
                  Row(children: [
                    const Icon(Icons.calendar_today, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Text("Due: $formattedDate",
                        style: const TextStyle(
                            fontSize: 16, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ]),

                  if (daysLeft >= 0) ...[
                    const SizedBox(height: 4),
                    Text("$daysLeft days left",
                        style: TextStyle(
                            fontSize: 14,
                            color: daysLeft <= 3 ? Colors.red : Colors.grey[700],
                            fontStyle: FontStyle.italic)),
                  ],

                  const Divider(height: 30),
                  const Text("Description",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5),
                  Text(data['description'] ?? '', style: const TextStyle(fontSize: 16)),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Activity'),
        content: const Text('Are you sure you want to delete this activity?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('activity').doc(activityId).delete();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
