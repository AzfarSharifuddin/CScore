import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileEditPage extends StatefulWidget {
  final bool openPassword;

  const ProfileEditPage({super.key, this.openPassword = false});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _nameController = TextEditingController();
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = _auth.currentUser!.uid;
    final doc = await _firestore.collection("users").doc(uid).get();

    if (doc.exists) {
      _data = doc.data()!;
      _nameController.text = _data!["name"] ?? "";
    }

    setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);

    try {
      final uid = _auth.currentUser!.uid;

      // --------------------------
      // UPDATE NAME in Firestore
      // --------------------------
      await _firestore.collection("users").doc(uid).update({
        "name": _nameController.text.trim(),
        "updatedAt": Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e")),
      );
    }

    setState(() => _saving = false);
  }

  Future<void> _changePassword() async {
    setState(() => _saving = true);

    try {
      final user = _auth.currentUser!;

      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _oldPassController.text.trim(),
      );

      // Re-authenticate
      await user.reauthenticateWithCredential(cred);

      // Update password
      await user.updatePassword(_newPassController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password changed successfully!")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password change failed: $e")),
      );
    }

    setState(() => _saving = false);
  }

  Widget _inputField(String label, TextEditingController controller,
      {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final role = _data?["role"] ?? "Student";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title:
            const Text("Edit Profile", style: TextStyle(color: Colors.black87)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------------------------------
            // NAME EDIT
            // ------------------------------------------------
            _inputField("Name", _nameController),

            // ------------------------------------------------
            // WARNING BOX FOR EMAIL (NOT EDITABLE)
            // ------------------------------------------------
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Email cannot be changed.\n(Admin approval is required for email changes.)",
                      style: TextStyle(fontSize: 13),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ------------------------------------------------
            // BUTTON: SAVE PROFILE
            // ------------------------------------------------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveProfile,
                icon: const Icon(Icons.save),
                label: const Text("Save Changes"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[700],
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ------------------------------------------------
            // PASSWORD CHANGE SECTION
            // ------------------------------------------------
            Text(
              "Change Password",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _inputField("Old Password", _oldPassController, obscure: true),
            _inputField("New Password", _newPassController, obscure: true),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _changePassword,
                icon: const Icon(Icons.lock_reset),
                label: const Text("Update Password"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
