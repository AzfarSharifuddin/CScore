import 'package:flutter/material.dart';
import 'package:cscore/ProgressTrackerModule/Model/progress_record.dart';
import 'package:cscore/ProgressTrackerModule/Services/progress_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddProgressPage extends StatefulWidget {
  @override
  _AddProgressPageState createState() => _AddProgressPageState();
}

class _AddProgressPageState extends State<AddProgressPage> {
  final nameCtrl = TextEditingController();
  final scoreCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Progress")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: "Activity Name"),
            ),
            TextField(
              controller: scoreCtrl,
              decoration: InputDecoration(labelText: "Score"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || scoreCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                final record = ProgressRecord(
                  id: '',
                  activityName: nameCtrl.text,
                  completedAt: DateTime.now(),
                  score: double.tryParse(scoreCtrl.text) ?? 0.0,
                  status: "completed",
                );

                final userId = FirebaseAuth.instance.currentUser!.uid;
                await ProgressService().addProgress(userId, record);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Progress added successfully!')),
                );

                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
