import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/Announcement.dart';

class EditAnnouncementPage extends StatefulWidget {
  final Announcement announcement;

  const EditAnnouncementPage({super.key, required this.announcement});

  @override
  _EditAnnouncementPageState createState() => _EditAnnouncementPageState();
}

class _EditAnnouncementPageState extends State<EditAnnouncementPage> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.announcement.title);
    _descriptionController =
        TextEditingController(text: widget.announcement.description);
    _dateController = TextEditingController(text: widget.announcement.date);
  }

  Future<void> _saveChanges() async {
    await FirebaseFirestore.instance
        .collection('announcement') // 🔥 UPDATED COLLECTION NAME
        .doc(widget.announcement.id) // 🔥 NOW VALID because model updated
        .update({
      'Title': _titleController.text.trim(),
      'Description': _descriptionController.text.trim(),
      'Date': _dateController.text.trim(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Announcement Updated Successfully")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Announcement")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(labelText: "Date"),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveChanges,
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}
