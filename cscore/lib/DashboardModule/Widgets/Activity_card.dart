import 'package:flutter/material.dart';
import '../Models/Activity.dart';

class ActivityCard extends StatelessWidget {
  final Activity activity;
  const ActivityCard({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: Colors.blueGrey[50],
      child: ListTile(
        leading: const Icon(Icons.event_note, color: Colors.blueGrey),
        title: Text(activity.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${activity.date}\n${activity.notes}'),
        isThreeLine: true,
      ),
    );
  }
}
