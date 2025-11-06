import 'package:flutter/material.dart';
import 'package:cscore/ProgressTrackerModule/Model/progress_record.dart';
import 'package:cscore/ProgressTrackerModule/Services/progress_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProgressPage extends StatefulWidget {
  final ProgressRecord record;

  const EditProgressPage({Key? key, required this.record}) : super(key: key);

  @override
  _EditProgressPageState createState() => _EditProgressPageState();
}

class _EditProgressPageState extends State<EditProgressPage> {
  late TextEditingController nameCtrl;
  late TextEditingController scoreCtrl;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.record.activityName);
    scoreCtrl = TextEditingController(text: widget.record.score.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Progress")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Activity Name"),
            ),
            TextField(
              controller: scoreCtrl,
              decoration: const InputDecoration(labelText: "Score"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final userId = FirebaseAuth.instance.currentUser!.uid;

                final updatedRecord = ProgressRecord(
                  id: widget.record.id,
                  activityName: nameCtrl.text,
                  completedAt: widget.record.completedAt,
                  score: double.tryParse(scoreCtrl.text) ?? widget.record.score,
                  status: widget.record.status,
                );

                await ProgressService().updateProgress(userId, updatedRecord);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Progress updated successfully!')),
                );

                Navigator.pop(context);
              },
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }
}
