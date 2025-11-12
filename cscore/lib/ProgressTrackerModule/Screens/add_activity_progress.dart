// add_activity_progress.dart
import 'package:flutter/material.dart';
import 'package:cscore/ProgressTrackerModule/Model/progress_record.dart';
import 'package:cscore/ProgressTrackerModule/Services/progress_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddActivityProgressPage extends StatefulWidget {
  const AddActivityProgressPage({super.key});

  @override
  State<AddActivityProgressPage> createState() => _AddActivityProgressPageState();
}

class _AddActivityProgressPageState extends State<AddActivityProgressPage> {
  final nameCtrl = TextEditingController();
  final scoreCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    scoreCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = nameCtrl.text.trim();
    final score = double.tryParse(scoreCtrl.text.trim()) ?? 0.0;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final record = ProgressRecord(
        id: '',
        activityName: name,
        completedAt: DateTime.now(),
        score: score,
        status: 'completed',
        type: 'activity',
      );
      final userId = FirebaseAuth.instance.currentUser!.uid;
      await ProgressService().addProgress(userId, record);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Progress added successfully!")));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Activity Progress")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: "Activity Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: scoreCtrl,
              decoration: const InputDecoration(
                labelText: "Score",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
