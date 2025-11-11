

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cscore/ForumModule/forum.dart';


class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String selectedTab = "users";
  String selectedFilter = "All";
  String searchQuery = "";

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  void _approveAllPending() async {
    final batch = _firestore.batch();

    final pendingUsers = await _firestore
        .collection('users')
        .where('status', isEqualTo: 'Pending')
        .get();

    for (var doc in pendingUsers.docs) {
      batch.update(doc.reference, {
        'status': 'Active',
        'updatedAt': Timestamp.now(),
      });
    }

    await batch.commit();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All pending users approved!')),
    );
  }

  void _updateUserStatus(String docId, String status) async {
    await _firestore.collection('users').doc(docId).update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('User status updated to $status')));
  }

  void _deleteUser(String docId) async {
    try {
      await _firestore.collection('users').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted from Firestore.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting user: $e')),
      );
    }
  }

  void _showEditUserSheet(Map<String, dynamic> user, String docId) {
    final TextEditingController nameController =
        TextEditingController(text: user['name'] ?? '');
    String role = user['role'] ?? 'Student';

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Edit User',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: role,
              items: const [
                DropdownMenuItem(value: 'Student', child: Text('Student')),
                DropdownMenuItem(value: 'Teacher', child: Text('Teacher')),
                DropdownMenuItem(value: 'Admin', child: Text('Admin')),
              ],
              onChanged: (value) => role = value ?? role,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await _firestore.collection('users').doc(docId).update({
                  'name': nameController.text,
                  'role': role,
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showUserProfile(Map<String, dynamic> user, String docId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("User Profile",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blueGrey.withOpacity(0.2),
                child: const Icon(Icons.person, size: 40),
              ),
              title: Text(user["name"] ?? user['email'] ?? 'No name'),
              subtitle: Text("${user["role"]}\n${user["email"]}"),
              trailing: Text(
                "[${user["status"]}]",
                style: TextStyle(
                  color: user["status"] == "Active"
                      ? Colors.green
                      : user["status"] == "Pending"
                          ? Colors.orange
                          : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (user["status"] == "Pending") ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _updateUserStatus(docId, "Active");
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("Approve Registration"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 10),
            ],

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _updateUserStatus(docId, 'Suspended');
              },
              icon: const Icon(Icons.pause_circle_outline),
              label: const Text("Suspend Account"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showEditUserSheet(user, docId);
              },
              icon: const Icon(Icons.edit),
              label: const Text("Edit Profile"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _deleteUser(docId);
              },
              icon: const Icon(Icons.delete),
              label: const Text("Delete Account"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading users'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        List docs = snapshot.data!.docs;

        docs = docs.where((doc) {
          final user = doc.data() as Map<String, dynamic>;
          final matchesSearch = user['name']
                  ?.toLowerCase()
                  .contains(searchQuery.toLowerCase()) ??
              user['email']
                  ?.toLowerCase()
                  .contains(searchQuery.toLowerCase()) ??
              false;

          final matchesFilter = selectedFilter == "All" ||
              user['status'] == selectedFilter;

          return matchesSearch && matchesFilter;
        }).toList();

        if (docs.isEmpty) {
          return const Center(child: Text('No users found'));
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() => searchQuery = value);
                },
              ),
            ),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip("All"),
                  _buildFilterChip("Pending"),
                  _buildFilterChip("Active"),
                  _buildFilterChip("Suspended"),
                ],
              ),
            ),

            if (selectedFilter == "Pending")
              Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton.icon(
                  onPressed: _approveAllPending,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text("Approve All Pending Users"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),

            Expanded(
              child: ListView.builder(
                itemCount: docs.length,
                padding: const EdgeInsets.all(12),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final user = doc.data() as Map<String, dynamic>;
                  final status = user['status'] ?? 'Pending';

                  Color statusColor = Colors.orange;
                  if (status == 'Active') statusColor = Colors.green;
                  if (status == 'Suspended' || status == 'Deleted')
                    statusColor = Colors.red;

                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withOpacity(0.2),
                        child: Icon(Icons.person, color: statusColor),
                      ),
                      title: Text(user['name'] ?? user['email'] ?? 'No name'),
                      subtitle: Text(
                          "${user['role'] ?? 'Student'}\n${user['email'] ?? ''}"),
                      trailing: Text(
                        "[$status]",
                        style: TextStyle(
                            color: statusColor, fontWeight: FontWeight.w600),
                      ),
                      onTap: () => _showUserProfile(user, doc.id),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ChoiceChip(
        label: Text(label),
        selected: selectedFilter == label,
        onSelected: (_) => setState(() => selectedFilter = label),
      ),
    );
  }

  Widget _buildSystemLogs() {
    return const Center(
      child: Text(
        "System Logs Coming Soon...",
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }

  Widget _buildForumManager() {
    return const Forum();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title:
            const Text("Welcome, Admin!", style: TextStyle(color: Colors.black87)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text("Users"),
                  selected: selectedTab == "users",
                  onSelected: (_) => setState(() => selectedTab = "users"),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text("System Logs"),
                  selected: selectedTab == "logs",
                  onSelected: (_) => setState(() => selectedTab = "logs"),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text("Forums"),
                  selected: selectedTab == "forums",
                  onSelected: (_) => setState(() => selectedTab = "forums"),
                ),
              ],
            ),
          ),

          Expanded(
            child: selectedTab == "users"
                ? _buildUserList()
                : selectedTab == "forums"
                    ? _buildForumManager()
                    : _buildSystemLogs(),
          ),
        ],
      ),
    );
  }
}
