import 'package:flutter/material.dart';
import 'package:cscore/AccountModule/screen/login.dart'; 
class TeacherProfile extends StatelessWidget {
  const TeacherProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "User Profile",
          style: TextStyle(color: Colors.black87),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          children: [

            // -------------------------
            // PROFILE PHOTO
            // -------------------------
            const CircleAvatar(
              radius: 55,
              backgroundImage: AssetImage("assets/images/profile.jpg"),
            ),

            const SizedBox(height: 16),

            // -------------------------
            // NAME + ROLE
            // -------------------------
            const Text(
              "Muhammad Thaqif",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.badge_rounded, size: 18, color: Colors.black54),
                SizedBox(width: 6),
                Text(
                  "Teacher",
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                )
              ],
            ),

            const SizedBox(height: 20),

            // -------------------------
            // INFO BOX
            // -------------------------
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                children: [

                  Row(
                    children: const [
                      Icon(Icons.email_rounded, color: Colors.black87),
                      SizedBox(width: 12),
                      Text(
                        "Email",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Spacer(),
                      Text("thaqif@utm.my"),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: const [
                      Icon(Icons.credit_card_rounded, color: Colors.black87),
                      SizedBox(width: 12),
                      Text(
                        "User ID",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Spacer(),
                      Text("UTM2025-01"),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // -------------------------
            // BUTTON: Edit Profile
            // -------------------------
            buildProfileButton(
              icon: Icons.settings_rounded,
              text: "Edit Profile",
              onPressed: () {
                // TODO: Open edit profile page
              },
            ),

            const SizedBox(height: 12),

            // -------------------------
            // BUTTON: Change Password
            // -------------------------
            buildProfileButton(
              icon: Icons.lock_outline_rounded,
              text: "Change Password",
              onPressed: () {
                // TODO: Open change password page
              },
            ),

            const SizedBox(height: 12),

            // -------------------------
            // BUTTON: Add Qualification
            // -------------------------
            buildProfileButton(
              icon: Icons.school_rounded,
              text: "Add Qualification",
              onPressed: () {
                // TODO: Navigate to add qualification page
              },
            ),

            const SizedBox(height: 12),

            // -------------------------
            // LOGOUT BUTTON
            // -------------------------
            buildProfileButton(
              icon: Icons.logout_rounded,
              text: "Logout",
              textColor: Colors.red,
              iconColor: Colors.red,
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false, // Clear all previous screens
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Reusable button widget
  Widget buildProfileButton({
    required IconData icon,
    required String text,
    Color iconColor = Colors.black87,
    Color textColor = Colors.black87,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 12),
              Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
