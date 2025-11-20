import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageQualificationPage extends StatefulWidget {
  const ManageQualificationPage({super.key});

  @override
  State<ManageQualificationPage> createState() => _ManageQualificationPageState();
}

class _ManageQualificationPageState extends State<ManageQualificationPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _institutionController = TextEditingController();
  final _qualificationController = TextEditingController();

  Future<void> _addQualification() async {
    String institution = _institutionController.text.trim();
    String qualification = _qualificationController.text.trim();

    if (institution.isEmpty || qualification.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('All fields required')));
      return;
    }

    final uid = _auth.currentUser!.uid;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('qualification')
        .add({
      'institution': institution,
      'qualification': qualification,
      'createdAt': DateTime.now(),
    });

    _institutionController.clear();
    _qualificationController.clear();

    Navigator.pop(context);
  }

  void _openAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Qualification"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _institutionController,
              decoration: const InputDecoration(labelText: "Institution Name"),
            ),
            TextField(
              controller: _qualificationController,
              decoration: const InputDecoration(labelText: "Name of Qualification"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: _addQualification,
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteQualification(String id) async {
    final uid = _auth.currentUser!.uid;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('qualification')
        .doc(id)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Manage Qualifications"),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder(
        stream: _firestore
            .collection('users')
            .doc(uid)
            .collection('qualification')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No qualifications added yet",
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final id = docs[i].id;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Institute: ${data['institution']}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Qualification: ${data['qualification']}",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),

                    // Delete button
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteQualification(id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
