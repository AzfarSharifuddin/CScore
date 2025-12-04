import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeactivateAccountPage extends StatefulWidget {
  const DeactivateAccountPage({super.key});

  @override
  State<DeactivateAccountPage> createState() => _DeactivateAccountPageState();
}

class _DeactivateAccountPageState extends State<DeactivateAccountPage> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> _deactivate() async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final email = user.email!;
      final password = _passwordController.text.trim();

      // 🔐 1. Re-authenticate user
      final cred = EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(cred);

      // 🟥 2. Update Firestore status to "Deactivated"
      await _firestore.collection("user").doc(user.uid).update({
        "status": "Deactivated",
      });

      // 🚪 3. Sign out the user
      await _auth.signOut();

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Your account has been deactivated."),
          backgroundColor: Colors.orange,
        ),
      );

    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);

      String msg = "Error occurred.";
      if (e.code == "wrong-password") msg = "Incorrect password.";
      if (e.code == "invalid-credential") msg = "Invalid password.";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Deactivate Account"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "To deactivate your account, please enter your password for confirmation.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 30),

            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _deactivate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Deactivate Account", style: TextStyle(fontSize: 18)),
                  ),
          ],
        ),
      ),
    );
  }
}
