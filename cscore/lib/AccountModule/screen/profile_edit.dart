import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb; // ✅ IMPORTANT FIX

class ProfileEditPage extends StatefulWidget {
  final bool openPassword;

  const ProfileEditPage({super.key, this.openPassword = false});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;        // ✅ FIX
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final uid = _auth.currentUser!.uid;
    final doc = await _firestore.collection("users").doc(uid).get();

    if (doc.exists) {
      final data = doc.data()!;
      _nameController.text = data["name"] ?? "";
      _emailController.text = data["email"] ?? "";
    }

    setState(() => _loading = false);
  }

  // ------------------------------------------------------------------
  //  EMAIL + NAME UPDATE (PROTOTYPE MODE - INSTANT EMAIL CHANGE)
  // ------------------------------------------------------------------
  Future<void> saveProfile() async {
    setState(() => _saving = true);

    try {
      final fb.User user = _auth.currentUser!;  // ✅ FIXED TYPE
      final String uid = user.uid;

      final String oldEmail = user.email!;
      final String newEmail = _emailController.text.trim();
      final String newName = _nameController.text.trim();

      // If email changed
      if (newEmail != oldEmail) {
        if (_currentPassController.text.isEmpty) {
          throw "Enter your CURRENT password to change your email.";
        }

        final cred = fb.EmailAuthProvider.credential(
          email: oldEmail,
          password: _currentPassController.text.trim(),
        );

        // Re-authenticate
        await user.reauthenticateWithCredential(cred);

        // Update Firebase Auth email instantly
        //await user.updateEmail(newEmail);

        await user.reload(); // refresh auth state
      }

      // Update Firestore
      await _firestore.collection("users").doc(uid).update({
        "name": newName,
        "email": newEmail,
        "updatedAt": Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => _saving = false);
  }

  // ------------------------------------------------------------------
  //  PASSWORD CHANGE
  // ------------------------------------------------------------------
  Future<void> changePassword() async {
    setState(() => _saving = true);

    try {
      final fb.User user = _auth.currentUser!; // ✅ FIXED TYPE

      if (_currentPassController.text.isEmpty) {
        throw "Enter your current password.";
      }

      final cred = fb.EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPassController.text.trim(),
      );

      await user.reauthenticateWithCredential(cred);

      await user.updatePassword(_newPassController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password updated successfully!")),
      );

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password update failed: $e")),
      );
    }

    setState(() => _saving = false);
  }

  Widget inputField(String label, TextEditingController controller,
      {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text("Edit Profile",
            style: TextStyle(color: Colors.black87)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            inputField("Name", _nameController),
            inputField("Email", _emailController),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Changing email requires your CURRENT password.",
                style: TextStyle(fontSize: 12),
              ),
            ),

            inputField("Current Password (required for email change)",
                _currentPassController,
                obscure: true),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _saving ? null : saveProfile,
              icon: const Icon(Icons.save),
              label: const Text("Save Changes"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 0, 226, 158),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),

            const SizedBox(height: 40),
            const Text("Change Password",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),

            inputField("Current Password", _currentPassController,
                obscure: true),
            inputField("New Password", _newPassController, obscure: true),

            ElevatedButton.icon(
              onPressed: _saving ? null : changePassword,
              icon: const Icon(Icons.lock_reset),
              label: const Text("Update Password"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
