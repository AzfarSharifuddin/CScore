import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String selectedTab = "users";
  final List<Map<String, dynamic>> users = [
    {
      "name": "Alia binti Hassan",
      "email": "trrmails@snams.com",
      "role": "Teacher",
      "status": "Active",
      "color": Colors.green,
    },
    {
      "name": "David Lee",
      "email": "d.lee@example.com",
      "role": "Teacher",
      "status": "Pending",
      "color": Colors.orange,
    },
    {
      "name": "Siti Nurhaliza",
      "email": "siti.n@example.com",
      "role": "Teacher",
      "status": "Suspended",
      "color": Colors.red,
    },
  ];

  void _showUserProfile(Map<String, dynamic> user) {
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
            Text("User Profile",
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: CircleAvatar(
                radius: 30,
                backgroundColor: user["color"].withOpacity(0.2),
                child: const Icon(Icons.person, size: 40),
              ),
              title: Text(user["name"]),
              subtitle: Text("${user["role"]}\n${user["email"]}"),
              trailing: Text(
                "[${user["status"]}]",
                style: TextStyle(
                  color: user["color"],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit),
              label: const Text("Edit Profile"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  minimumSize: const Size(double.infinity, 50)),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.pause_circle_outline),
              label: const Text("Deactivate Account"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  minimumSize: const Size(double.infinity, 50)),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.delete),
              label: const Text("Delete Account"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 50)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _createForum() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Forum created successfully!")),
    );
  }

  void _deleteForum() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Forum deleted successfully!")),
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
      ),
      body: Column(
        children: [
          // Tabs
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
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
      floatingActionButton: selectedTab == "users"
          ? FloatingActionButton(
              onPressed: () {},
              backgroundColor: Colors.blueGrey,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildUserList() {
    return ListView.builder(
      itemCount: users.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: user["color"].withOpacity(0.2),
              child: Icon(Icons.person, color: user["color"]),
            ),
            title: Text(user["name"]),
            subtitle: Text("${user["role"]}\n${user["email"]}"),
            trailing: Text(
              "[${user["status"]}]",
              style: TextStyle(
                  color: user["color"], fontWeight: FontWeight.w600),
            ),
            onTap: () => _showUserProfile(user),
          ),
        );
      },
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Forum Management",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _createForum,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text("Create Forum"),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                minimumSize: const Size(double.infinity, 50)),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _deleteForum,
            icon: const Icon(Icons.delete_forever),
            label: const Text("Delete Forum"),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50)),
          ),
        ],
      ),
    );
  }
}