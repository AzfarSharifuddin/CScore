// add_learning_progress.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cscore/ProgressTrackerModule/Model/progress_record.dart';
import 'package:cscore/ProgressTrackerModule/Services/progress_service.dart';

class AddLearningProgressPage extends StatefulWidget {
  const AddLearningProgressPage({super.key});

  @override
  State<AddLearningProgressPage> createState() =>
      _AddLearningProgressPageState();
}

class _AddLearningProgressPageState extends State<AddLearningProgressPage> {
  String? _selectedTopic;
  String? _selectedFile;
  String _status = 'In Progress';
  final TextEditingController scoreCtrl = TextEditingController();
  bool _isLoading = false;

  Map<String, List<String>> topicFiles = {};

  @override
  void initState() {
    super.initState();
    _fetchTopicsAndFiles();
  }

  @override
  void dispose() {
    scoreCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchTopicsAndFiles() async {
    try {
      final tutorialsSnap = await FirebaseFirestore.instance
          .collection('tutorial')
          .get();
      final Map<String, List<String>> topicMap = {};
      for (final topicDoc in tutorialsSnap.docs) {
        final topicData = topicDoc.data();
        final topicName = (topicData['subtopic'] ?? '').toString().trim();
        final safeTopicName = topicName.isNotEmpty ? topicName : topicDoc.id;
        final filesSnap = await topicDoc.reference.collection('files').get();
        final List<String> files = filesSnap.docs
            .map((fileDoc) {
              final f = fileDoc.data();
              return (f['fileName'] ?? '').toString().trim();
            })
            .where((fileName) => fileName.isNotEmpty)
            .toList();
        topicMap[safeTopicName] = files;
      }
      if (mounted) setState(() => topicFiles = topicMap);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load tutorial files: $e')),
        );
    }
  }

  Future<void> _saveProgress() async {
    if (_selectedTopic == null || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select both a topic and a learning file"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final record = ProgressRecord(
        id: '',
        activityName: "${_selectedTopic!} - ${_selectedFile!}",
        completedAt: DateTime.now(),
        score: double.tryParse(scoreCtrl.text) ?? 0.0,
        status: _status,
        type: 'learning',
      );

      await ProgressService().addProgress(userId, record);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Learning progress added successfully!"),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = topicFiles.isEmpty;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF5F5F7),
        title: const Text(
          "Add Learning Progress",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select Topic",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedTopic,
                    items: topicFiles.keys
                        .map(
                          (topic) => DropdownMenuItem(
                            value: topic,
                            child: Text(topic),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedTopic = val;
                        _selectedFile = null;
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Select Learning File",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedFile,
                    items:
                        (_selectedTopic == null
                                ? <String>[]
                                : (topicFiles[_selectedTopic!] ?? <String>[]))
                            .map(
                              (f) => DropdownMenuItem(value: f, child: Text(f)),
                            )
                            .toList(),
                    onChanged: (val) => setState(() => _selectedFile = val),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_selectedTopic != null &&
                      (topicFiles[_selectedTopic!] ?? []).isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'No files uploaded yet for this topic.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    "Learning Status",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _status,
                    items: const [
                      DropdownMenuItem(
                        value: "In Progress",
                        child: Text("In Progress"),
                      ),
                      DropdownMenuItem(
                        value: "Completed",
                        child: Text("Completed"),
                      ),
                      DropdownMenuItem(
                        value: "Not Started",
                        child: Text("Not Started"),
                      ),
                    ],
                    onChanged: (val) =>
                        setState(() => _status = val ?? 'In Progress'),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: scoreCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Score (optional)",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading ? null : _saveProgress,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text("Save"),
                  ),
                ],
              ),
            ),
    );
  }
}
