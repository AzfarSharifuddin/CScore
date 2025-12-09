import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateForumScreen extends StatefulWidget {
  const CreateForumScreen({super.key});

  @override
  State<CreateForumScreen> createState() => _CreateForumScreenState();
}

class _CreateForumScreenState extends State<CreateForumScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPublic = true; // Default to public
  bool _isSubmitting = false;

  Future<void> _createForum() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to create a forum.')),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('user').doc(user.uid).get();
      final creatorName = userDoc.data()?['name'] ?? 'Anonymous';
      // Get the creator's role
      final creatorRole = userDoc.data()?['role'] ?? 'Student';

      await FirebaseFirestore.instance.collection('forum').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'creatorName': creatorName,
        'creatorId': user.uid,
        'creatorRole': creatorRole, // <-- Save the role here
        'timestamp': FieldValue.serverTimestamp(),
        'access': _isPublic ? 'public' : 'private',
        'members': [_isPublic ? 'all' : user.uid],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Forum created successfully!')),
      );
      Navigator.pop(context);

    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create forum: $e')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Forum'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Forum Title',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., CS101 Midterm Discussion'
                ),
                validator: (value) => value == null || value.isEmpty ? 'Title cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                 maxLines: 3,
                validator: (value) => value == null || value.isEmpty ? 'Description cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Public Forum'),
                subtitle: const Text('If public, all students can see this forum.'),
                value: _isPublic,
                onChanged: (bool value) {
                  setState(() {
                    _isPublic = value;
                  });
                },
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isSubmitting
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _createForum,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Forum', style: TextStyle(fontSize: 18)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
