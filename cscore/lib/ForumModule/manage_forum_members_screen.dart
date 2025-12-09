import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageForumMembersScreen extends StatefulWidget {
  final String forumId;

  const ManageForumMembersScreen({super.key, required this.forumId});

  @override
  State<ManageForumMembersScreen> createState() => _ManageForumMembersScreenState();
}

class _ManageForumMembersScreenState extends State<ManageForumMembersScreen> {
  late Future<List<DocumentSnapshot>> _allStudentsFuture;

  @override
  void initState() {
    super.initState();
    _allStudentsFuture = _getAllStudents();
  }

  Future<List<DocumentSnapshot>> _getAllStudents() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('user')
        .where('role', isEqualTo: 'Student')
        .get();
    return snapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Members'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('forum').doc(widget.forumId).snapshots(),
        builder: (context, forumSnapshot) {
          if (!forumSnapshot.hasData) return const Center(child: CircularProgressIndicator());

          final forumData = forumSnapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> members = forumData['members'] ?? [];

          return FutureBuilder<List<DocumentSnapshot>>(
            future: _allStudentsFuture,
            builder: (context, studentsSnapshot) {
              if (!studentsSnapshot.hasData) return const Center(child: CircularProgressIndicator());

              final allStudents = studentsSnapshot.data!;

              return ListView.builder(
                itemCount: allStudents.length,
                itemBuilder: (context, index) {
                  final student = allStudents[index];
                  final studentId = student.id;
                  final studentData = student.data() as Map<String, dynamic>;
                  final bool isMember = members.contains(studentId);

                  return SwitchListTile(
                    title: Text(studentData['name'] ?? studentId),
                    subtitle: Text(studentData['email'] ?? 'No email'),
                    value: isMember,
                    onChanged: (bool value) async {
                      if (value) {
                        // Add member
                        await FirebaseFirestore.instance.collection('forum').doc(widget.forumId).update({
                          'members': FieldValue.arrayUnion([studentId]),
                        });
                      } else {
                        // Remove member
                        await FirebaseFirestore.instance.collection('forum').doc(widget.forumId).update({
                          'members': FieldValue.arrayRemove([studentId]),
                        });
                      }
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
