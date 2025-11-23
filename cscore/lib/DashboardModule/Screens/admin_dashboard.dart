import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cscore/AccountModule/model/admin_edit_user_profile.dart'; // ← Import edit screen
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
  final TextEditingController _searchController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔐 LOGOUT
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  void _approveAllPending() async {
    final batch = _firestore.batch();

    final pending = await _firestore
        .collection('user')
        .where('status', isEqualTo: 'Pending')
        .get();

    for (var doc in pending.docs) {
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
    await _firestore.collection('user').doc(docId).update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User status updated to $status')),
    );
  }

  void _deleteUser(String docId) async {
    try {
      await _firestore.collection('user').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting user: $e')),
      );
    }
  }

  // 👤 SHOW USER DETAILS WITH EDIT BUTTON
  void _showUserProfile(Map<String, dynamic> user, String docId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
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
              title: Text(user["name"] ?? user["email"]),
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

            // 📝 EDIT PROFILE BUTTON (NEW)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminEditUserProfile(userId: docId),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text("Edit User Name"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),

            const SizedBox(height: 10),

            if (user["status"] == "Pending")
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _updateUserStatus(docId, "Active");
                },
                icon: const Icon(Icons.check),
                label: const Text("Approve Registration"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _updateUserStatus(docId, "Suspended");
              },
              icon: const Icon(Icons.pause),
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

  Widget _buildUserList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search by name or email...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => setState(() => searchQuery = val),
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
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('user').snapshots(),
            builder: (_, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              List docs = snapshot.data!.docs;

              docs = docs.where((d) {
                final user = d.data() as Map<String, dynamic>;

                final name = (user["name"] ?? "").toLowerCase();
                final email = (user["email"] ?? "").toLowerCase();
                final status = (user["status"] ?? "").toLowerCase();

                final matchesSearch = name.contains(searchQuery.toLowerCase()) ||
                    email.contains(searchQuery.toLowerCase());

                final matchesFilter = selectedFilter == "All" ||
                    status == selectedFilter.toLowerCase();

                return matchesSearch && matchesFilter;
              }).toList();

              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    "No users found for this filter.\nTry another filter or search.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final doc = docs[i];
                  final user = doc.data() as Map<String, dynamic>;

                  final status = user["status"] ?? "Pending";
                  Color statusColor = Colors.orange;
                  if (status == "Active") statusColor = Colors.green;
                  if (status == "Suspended") statusColor = Colors.red;

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withOpacity(0.2),
                        child: Icon(Icons.person, color: statusColor),
                      ),
                      title: Text(user["name"] ?? user["email"]),
                      subtitle: Text("${user["role"]}\n${user["email"] ?? ""}"),
                      trailing: Text(
                        "[$status]",
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => _showUserProfile(user, doc.id),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Welcome, Admin!",
          style: TextStyle(color: Colors.black87),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
          ),
        ],
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
                  label: const Text("Forums"),
                  selected: selectedTab == "forums",
                  onSelected: (_) => setState(() => selectedTab = "forums"),
                ),
              ],
            ),
          ),

          Expanded(
            child: selectedTab == "user"
                ? _buildUserList()
                : const Forum(),
          ),
        ],
      ),
    );
  }
}
