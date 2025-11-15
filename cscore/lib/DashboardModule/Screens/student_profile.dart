import 'package:flutter/material.dart';
import 'package:cscore/AccountModule/screen/login.dart'; // change to your login page

class StudentProfile extends StatelessWidget {
  const StudentProfile({super.key});

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

            // ---------------------------------------------------
            // PROFILE PICTURE
            // ---------------------------------------------------
            const CircleAvatar(
              radius: 55,
              backgroundImage: AssetImage("assets/images/profile.jpg"),
            ),

            const SizedBox(height: 16),

            // ---------------------------------------------------
            // NAME + ROLE
            // ---------------------------------------------------
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
                Icon(Icons.school_rounded, size: 18, color: Colors.black54),
                SizedBox(width: 6),
                Text(
                  "Student",
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                )
              ],
            ),

            const SizedBox(height: 20),

            // ---------------------------------------------------
            // INFORMATION BOX: Email ONLY
            // ---------------------------------------------------
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
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ---------------------------------------------------
            // BUTTON: Edit Profile
            // ---------------------------------------------------
            buildProfileButton(
              icon: Icons.settings_rounded,
              text: "Edit Profile",
              onPressed: () {
                // TODO: Implement Edit Profile
              },
            ),

            const SizedBox(height: 12),

            // ---------------------------------------------------
            // BUTTON: Change Password
            // ---------------------------------------------------
            buildProfileButton(
              icon: Icons.lock_outline_rounded,
              text: "Change Password",
              onPressed: () {
                // TODO: Implement Change Password
              },
            ),

            const SizedBox(height: 12),

            // ---------------------------------------------------
            // BUTTON: Logout
            // ---------------------------------------------------
            buildProfileButton(
              icon: Icons.logout_rounded,
              text: "Logout",
              iconColor: Colors.red,
              textColor: Colors.red,
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------
  // REUSABLE BUTTON WIDGET
  // ---------------------------------------------------
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
