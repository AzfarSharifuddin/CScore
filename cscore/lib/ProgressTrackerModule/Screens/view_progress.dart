import 'package:flutter/material.dart';
import 'package:cscore/ProgressTrackerModule/Services/progress_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cscore/ProgressTrackerModule/config/demo_config.dart';



class ViewProgressScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = getCurrentUserId();


    return Scaffold(
      appBar: AppBar(title: Text("My Progress")),
      body: StreamBuilder(
        stream: ProgressService().getProgressStream(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final progress = snapshot.data!;
          return ListView.builder(
            itemCount: progress.length,
            itemBuilder: (context, i) {
              final p = progress[i];
              return ListTile(
                title: Text(p.activityName),
                subtitle: Text("Score: ${p.score} | ${p.completedAt}"),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => ProgressService().deleteProgress(userId, p.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
